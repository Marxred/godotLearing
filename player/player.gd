class_name Player
extends CharacterBody2D

enum Direction{
	LEFT = -1,
	#MIDDLE = 0,
	RIGHT = 1,
}
@export_group("Direction")#设定方向
@export var direction :Direction= Direction.RIGHT:
	set(v):
		if is_zero_approx(v):
			return
		direction = v
		if not is_node_ready():
			await ready
		graphic_2d.scale.x = direction


enum State{
	IDLE, RUN,
	JUMP, FALL, LAND, SLIDE_FLOOR,
	WALL_SLIDE, WALL_JUMP,
	ATTACK, ATTACK_COMBO, ATTACK_CRITICAL,
	HURT, DIE,
}
const state_to_animation_name:Dictionary={
	State.IDLE:"idle", State.RUN:"run",
	State.JUMP:"jump", State.FALL:"fall", State.LAND:"land", State.SLIDE_FLOOR:"slide_floor",
	State.WALL_SLIDE:"slide_wall", State.WALL_JUMP:"jump",
	State.ATTACK:"attack", State.ATTACK_COMBO:"attack_combo", State.ATTACK_CRITICAL:"attack_critical",
	State.HURT:"hurt", State.DIE:"die",
}

const sfx_name:Array = [null,null,"Jump",null,null,null,null,null,"Attack","AttackCombo","AttackCritical","Hurt","Die"]

const GROUND_STATES : Array[State] =[
	State.IDLE, State.RUN,  State.LAND,State.SLIDE_FLOOR,
	State.ATTACK, State.ATTACK_COMBO, State.ATTACK_CRITICAL,]
const ATTACK_STATE: Array[State] = [
	State.ATTACK, State.ATTACK_COMBO, State.ATTACK_CRITICAL,]
const AIR_STATE: Array[State] = [State.JUMP, State.FALL, State.WALL_JUMP,]

#计时器设定
@export_group("Invincible Time","INVINCIBLE_TIME_")
const COYOTE_TIME: float = 0.05
const JUMP_REQUEST_TIME: float = .1#极小数会导致无法起跳，极大数无影响
@export var INVINCIBLE_TIME_FLOOR_SLIDING: float = .45
@export var INVINCIBLE_TIME_HURT: float = 1.28

#初始化参数
@export_group("Speed", "SPEED_")
@export var SPEED_JUMP: float = -300.0##跳跃速度
@export var SPEED_RUN_MAX : float= 125##跑步速度
@export var SPEED_WALL_JUMP: Vector2 = Vector2(250.0, -200.0)##靠墙跳速度
const FLOOR_ACCELERATE_TIME : float = 0.1
var FLOOR_ACCELERATION : float = SPEED_RUN_MAX / FLOOR_ACCELERATE_TIME
const SLIDING_SPEED: float = 250.0
var SLIDING_FRICTION: float = SLIDING_SPEED / 0.45
const AIR_ACCELERATE_TIME : float = 0.2
var AIR_ACCELERATION : float = SPEED_RUN_MAX / AIR_ACCELERATE_TIME
var default_gravity : float = ProjectSettings.get("physics/2d/default_gravity")
var KNOCKBACK:float = 256.0
var first_tick: bool


#初始化资源
@onready var state_machine: StateMachine = $StateMachine
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var sliding_timer: Timer = $SlidingTimer
@onready var attack_request_timer: Timer = $AttackRequestTimer
@onready var invincible_timer_hurt: Timer = $InvincibleTimer
@onready var sliding_invincible_timer: Timer = $SlidingInvincibleTimer
@onready var hand_checker: RayCast2D = $Graphic2D/HandChecker
@onready var foot_checker: RayCast2D = $Graphic2D/FootChecker
@onready var hurtbox: CollisionShape2D = $Graphic2D/Hurtbox/hurtbox
@onready var hitbox: CollisionShape2D = $Graphic2D/HitBox/hitbox
@onready var stats: Stats = Game.player_stats
var pending_damage: Damage
@onready var graphic_2d: Node2D = $Graphic2D
@onready var animation_playerStates: AnimationPlayer = $AnimationPlayerStates
@onready var animation_interact: AnimatedSprite2D = $AnimationInteract
var interact_item: Array[Interactable]
@onready var pause_screen: Control = $UI/PauseScreen
@onready var status_panel: HBoxContainer = $UI/status_panel
@onready var game_over_screen: Control = $UI/GameOverScreen


func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start(JUMP_REQUEST_TIME)
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < SPEED_JUMP /2.0:
			velocity.y = SPEED_JUMP /2.0
	if event.is_action_pressed("attack"):
		attack_request_timer.start()
	if event.is_action_pressed("sliding"):
		sliding_timer.start()
	if event.is_action_pressed("interact")\
	and can_interact():
		interact_item.back().interact()
	if event.is_action_pressed("pause"):
		pause_screen.show_pause()

#状态变换判断
##先判断人物血量，
func get_next_state(state: State)-> State:
	if stats.health <= 0:
		return State.DIE
	if pending_damage != null:
		state_machine.ENTER_CURRENT_STATE_AGAIN = true
		return State.HURT
	
	if state in GROUND_STATES and not is_on_floor():
		return State.FALL
	
	if should_jump():
		return State.JUMP
	if should_slide(state):
		return State.SLIDE_FLOOR
	if should_attack(state):
		return State.ATTACK
	
	#为接下来的判断准备，有待修改
	var movement: float = Input.get_axis("move_left","move_right")
	var is_still : bool = is_zero_approx(movement) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if not is_still:
				return State.RUN
		State.RUN:
			if is_still:
				return State.IDLE
		
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			if should_wall_sliding_from_raycast():
				return State.WALL_SLIDE
		State.FALL:
			if is_on_floor():
				return State.LAND
			if should_wall_sliding_from_raycast():
				return State.WALL_SLIDE
		State.LAND:
			if not animation_playerStates.is_playing() or not is_still:
				return State.IDLE
		State.SLIDE_FLOOR:
			if not animation_playerStates.is_playing() or is_on_wall():
				return State.IDLE
		
		State.WALL_SLIDE:
			if is_on_floor():
				return State.IDLE
			if not should_wall_sliding_from_raycast():
				return State.FALL
			if jump_request_timer.time_left:
				return State.WALL_JUMP
		State.WALL_JUMP:
			if velocity.y >= 0:
				return State.FALL
			if should_wall_sliding_from_raycast():
				return State.WALL_SLIDE
		
		State.ATTACK:
			if not animation_playerStates.is_playing():
				if attack_request_timer.time_left > 0.0:
					return State.ATTACK_COMBO
				else: return State.IDLE
		State.ATTACK_COMBO:
			if not animation_playerStates.is_playing():
				if attack_request_timer.time_left > 0.0:
					return State.ATTACK_CRITICAL
				else: return State.IDLE
		State.ATTACK_CRITICAL:
			if not animation_playerStates.is_playing():
				return State.IDLE
		
		State.HURT:
			if not animation_playerStates.is_playing():
				return State.IDLE
	return state

#状态转换函数，进行状态的初始化
func transition_state(from: State, to: State)-> void:
	first_tick = true
	if from == State.SLIDE_FLOOR:
		sliding_invincible_timer.stop()
	match to:
		State.IDLE:
			animation_playerStates.play(state_to_animation_name.get(State.IDLE))
		State.RUN:
			animation_playerStates.play(state_to_animation_name.get(State.RUN))
		
		State.JUMP:
			animation_playerStates.play(state_to_animation_name.get(State.JUMP))
			SoundManager.play_sfx(sfx_name[State.JUMP])
			velocity.y = SPEED_JUMP
			coyote_timer.stop()
			jump_request_timer.stop()
		State.FALL:
			animation_playerStates.play(state_to_animation_name.get(State.FALL))
			if from in GROUND_STATES:
				coyote_timer.start(COYOTE_TIME)
		State.LAND:
			animation_playerStates.play(state_to_animation_name.get(State.LAND))
		State.SLIDE_FLOOR:
			animation_playerStates.play(state_to_animation_name.get(State.SLIDE_FLOOR))
			sliding_invincible_timer.start(INVINCIBLE_TIME_FLOOR_SLIDING)
			sliding_timer.stop()
			stats.energy -= 1.0
			velocity.x = graphic_2d.scale.x * SLIDING_SPEED
		
		State.WALL_SLIDE:
			animation_playerStates.play(state_to_animation_name.get(State.WALL_SLIDE))
			velocity = Vector2(500.0, 0.0) * -get_wall_normall_direction()
		State.WALL_JUMP:
			animation_playerStates.play(state_to_animation_name.get(State.WALL_JUMP))
			var wall_normall_direction : int = get_wall_normall_direction()
			velocity = SPEED_WALL_JUMP
			velocity.x *= wall_normall_direction
			graphic_2d.scale.x = wall_normall_direction
			jump_request_timer.stop()
		
		State.ATTACK:
			animation_playerStates.play(state_to_animation_name.get(State.ATTACK))
			SoundManager.play_sfx(sfx_name[State.ATTACK])
		State.ATTACK_COMBO:
			animation_playerStates.play(state_to_animation_name.get(State.ATTACK_COMBO))
			print("State.ATTACK_COMBO ",State.ATTACK_COMBO)
			SoundManager.play_sfx(sfx_name[State.ATTACK_COMBO])
		State.ATTACK_CRITICAL:
			animation_playerStates.play(state_to_animation_name.get(State.ATTACK_CRITICAL))
			SoundManager.play_sfx(sfx_name[State.ATTACK_CRITICAL])
		State.HURT:
			invincible_timer_hurt.start(INVINCIBLE_TIME_HURT)
			animation_playerStates.play(state_to_animation_name.get(State.HURT))
			stats.health -= pending_damage.damage
			var dam_dir:Vector2 = self.global_position.direction_to(\
							pending_damage.source.global_position)
			pending_damage = null
			graphic_2d.scale.x = dam_dir.sign().x if dam_dir \
									else graphic_2d.scale.x
			velocity = KNOCKBACK *-dam_dir
			SoundManager.play_sfx(sfx_name[State.HURT])
		State.DIE:
			animation_playerStates.play(state_to_animation_name.get(State.DIE))
			SoundManager.play_sfx(sfx_name[State.DIE])
	print(owner.name, 
		" [ %s ] << from %s to %s >> " % [
		Engine.get_physics_frames(),
		State.keys()[from] if from >= 0 else "<START>" ,
		State.keys()[to]
		],
		"velocity ",velocity
		)

#状态的物理帧处理
func tick_physics(state: State, delta: float) -> void:
	interact_ani_play()
	if state in [State.IDLE, State.RUN, State.HURT]:
		recover_energy(delta)
	if invincible_timer_hurt.time_left >0.0:
		sparkle_sprite()
	else: graphic_2d.modulate.a = 1
	match state:
		State.RUN, State.FALL, State.LAND:
			move(default_gravity, delta)
		State.JUMP:
			move(0.0 if state_machine.state_time == 0.0\
					else default_gravity, delta)
		State.SLIDE_FLOOR:
			slide(default_gravity, delta)
		State.WALL_SLIDE:
			move_self(default_gravity / 1000.0, delta)
		State.WALL_JUMP:
			move(0.0 if state_machine.state_time == 0.0\
					else default_gravity, delta)
			
		State.HURT, State.IDLE:
			move_self(default_gravity, delta)
			
		State.ATTACK:
			#enable_hitbox(0.3, 0.5)
			move_self(default_gravity, delta)
		State.ATTACK_COMBO:
			#enable_hitbox(0.0, 0.1)
			move_self(default_gravity, delta)
		State.ATTACK_CRITICAL:
			#enable_hitbox(0.1, 0.6)
			move_self(default_gravity, delta)
			
		State.DIE:
			move_self(default_gravity, delta)
	first_tick = false
	move_and_slide()

#进行条件判断的函数们
func should_wall_sliding_from_colliding()-> bool:
	return is_on_wall() \
			and hand_checker.is_colliding() \
			and foot_checker.is_colliding() \
			and Input.is_action_pressed("catch_wall")

func should_wall_sliding_from_raycast()-> bool:
	return hand_checker.is_colliding() \
			and foot_checker.is_colliding() \
			and Input.is_action_pressed("catch_wall")

func should_jump()-> bool:
	var _can_jump : bool = is_on_floor() or coyote_timer.time_left
	var _should_jump : bool = _can_jump and jump_request_timer.time_left
	return _should_jump

func should_slide(state: State)-> bool:
	return stats.energy and sliding_timer.time_left > 0\
			and state in GROUND_STATES

func should_attack(state: State)->bool:
	return not state in ATTACK_STATE \
			and state in GROUND_STATES \
			and attack_request_timer.time_left > 0.0

func get_wall_normall_direction()-> int:
	return -foot_checker.global_position.direction_to(\
			foot_checker.get_collision_point())\
			.sign().x as int

func enable_hitbox(from:float, to:float)-> void:
	var AniPos : float = animation_playerStates.current_animation_position
	if from < AniPos and AniPos < to:
		hitbox.set_disabled(false)
	else:
		hitbox.set_disabled(true)

func invincible_total_time_left()->float:
	return maxf(invincible_timer_hurt.time_left, sliding_invincible_timer.time_left)

func sparkle_sprite()-> void:
	graphic_2d.modulate.a = sin(invincible_total_time_left() * 16) * 0.5 + 0.5

func recover_energy(delta: float)->void:
	stats.energy += delta

#玩家输入进行移动
func move(gravity: float, delta: float)-> void:
	var acceleration : float = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	var movement = Input.get_axis("move_left","move_right")
	velocity.x = move_toward(velocity.x, SPEED_RUN_MAX * movement, acceleration * delta)#x方向移动
	velocity.y += gravity * delta#y方向移动
	if sign(movement):#翻转图像
		direction = sign(movement)

#忽略玩家输入的移动
func move_self(gravity: float, delta: float)-> void:
	var acceleration : float = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)#x方向移动
	velocity.y += gravity * delta#y方向移动

func slide(gravity: float, delta: float)->void:
	var acceleration : float = SLIDING_FRICTION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += gravity * delta#y方向移动

func die()->void:
	game_over_screen.show_game_over()

func damage_inti(_hitbox: HitBox)->Damage:
	var _pending_damage = Damage.new()
	_pending_damage.damage = 1
	_pending_damage.source = _hitbox
	return _pending_damage

func _on_hurtbox_hurt(_hitbox: HitBox) -> void:
	if invincible_total_time_left() > 0.0:
		return
	pending_damage = damage_inti(_hitbox)

func can_interact()-> bool:
	return not interact_item.is_empty()\
			and state_machine.current_state != State.DIE

func interact_ani_play()->void:
	animation_interact.visible = can_interact()
	if animation_interact.visible:
		animation_interact.play()
	else:
		animation_interact.stop()

func register_interact(item: Interactable)->void:
	if interact_item.has(item):
		return
	interact_item.push_back(item)

func erase_interact(item: Interactable)->void:
	if interact_item.has(item):
		interact_item.erase(item)
	return
