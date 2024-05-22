extends CharacterBody2D


enum State{
	IDLE,
	RUNING,
	JUMPING,
	FALLING,
	LANDING,
	WALL_SLIDING,
	WALL_JUMPING,
	ATTACK,
	COMBO_ATTACK,
	CRITICAL_ATTACK,
}
const GROUND_STATES : Array[State] =[
	State.IDLE, State.RUNING,  State.LANDING,
	State.ATTACK, State.COMBO_ATTACK, State.CRITICAL_ATTACK,]
const ATTACK_STATE: Array[State] = [
	State.ATTACK, State.COMBO_ATTACK, State.CRITICAL_ATTACK,]
const AIR_STATE: Array[State] = [State.JUMPING, State.FALLING, State.WALL_JUMPING,]
const FLOOR_ACCELERATE_TIME : float = 0.1
const AIR_ACCELERATE_TIME : float = 0.2
const COYOTE_TIME: float = 0.05
const JUMP_REQUEST_TIME: float = .1#不能太小，会导致无法起跳；极大数无影响，极小数有影响

#初始化参数
@export var JUMP_SPEED: float = -300.0##跳跃速度
@export var RUN_SPEED_MAX : float= 125##跑步速度
@export var WALL_JUMP_SPEED: Vector2 = Vector2(250.0, -200.0)##靠墙跳速度
var FLOOR_ACCELERATION : float = RUN_SPEED_MAX / FLOOR_ACCELERATE_TIME
var AIR_ACCELERATION : float = RUN_SPEED_MAX / AIR_ACCELERATE_TIME
var default_gravity : float = ProjectSettings.get("physics/2d/default_gravity")
var is_first_tick: bool = false

#初始化资源
@onready var state_machine: StateMachine = $StateMachine
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var attack_request_timer: Timer = $AttackRequestTimer
@onready var graphic_2d: Node2D = $Graphic2D
@onready var animation_playerStates: AnimationPlayer = $Animation_PlayerStates
@onready var hand_checker: RayCast2D = $Graphic2D/HandChecker
@onready var foot_checker: RayCast2D = $Graphic2D/FootChecker


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.set_wait_time(JUMP_REQUEST_TIME)
		jump_request_timer.start()
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_SPEED /2.0:
			velocity.y = JUMP_SPEED /2.0
	if event.is_action_pressed("attack"):
		attack_request_timer.start()

func can_wall_sliding_use_colliding()-> bool:
	return is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding() and Input.is_action_pressed("catch_wall")

func can_wall_sliding_use_raycast()-> bool:
	return hand_checker.is_colliding() and foot_checker.is_colliding() and Input.is_action_pressed("catch_wall")

func get_wall_normall_direction()-> int:
	return -1 if (foot_checker.get_collision_point() - foot_checker.global_position).x > 0 else 1

func should_jump()-> bool:
	var can_jump : bool = is_on_floor() or coyote_timer.time_left
	var should_jump : bool = can_jump and jump_request_timer.time_left
	return should_jump

#状态变换判断
func get_next_state(state: State)-> State:
	var direction: float = Input.get_axis("move_left","move_right")
	var is_still : bool = is_zero_approx(direction) and is_zero_approx(velocity.x)
	if state in GROUND_STATES and not is_on_floor():
		return State.FALLING
	if should_jump():
		return State.JUMPING
	if not state in ATTACK_STATE and state in GROUND_STATES and attack_request_timer.time_left > 0:
		return State.ATTACK
	
	match state:
		State.IDLE:
			if not is_still:
				return State.RUNING
			if attack_request_timer.time_left:
				return State.ATTACK
		State.RUNING:
			if is_still:
				return State.IDLE
			if attack_request_timer.time_left:
				return State.ATTACK
		State.JUMPING:
			if velocity.y >= 0 and not is_first_tick:
				return State.FALLING
			if can_wall_sliding_use_raycast() and not is_first_tick:
				return State.WALL_SLIDING
			
		State.FALLING:
			if is_on_floor():
				return State.LANDING
			if can_wall_sliding_use_raycast() and not is_first_tick:
				return State.WALL_SLIDING
			
		State.LANDING:
			if not animation_playerStates.is_playing() or not is_still:
				return State.IDLE
			if attack_request_timer.time_left:
				return State.ATTACK
		State.WALL_SLIDING:
			if is_on_floor():
				return State.IDLE
			if not can_wall_sliding_use_raycast():
				return State.FALLING
			if jump_request_timer.time_left:
				return State.WALL_JUMPING
			
		State.WALL_JUMPING:
			if velocity.y >= 0:
				return State.FALLING
			if can_wall_sliding_use_raycast():
				return State.WALL_SLIDING
			
		State.ATTACK:
			if not animation_playerStates.is_playing():
				if attack_request_timer.time_left > 0:
					return State.COMBO_ATTACK
				else: return State.IDLE
			
		State.COMBO_ATTACK:
			if not animation_playerStates.is_playing():
				if attack_request_timer.time_left > 0:
					return State.CRITICAL_ATTACK
				else: return State.IDLE
		State.CRITICAL_ATTACK:
			if not animation_playerStates.is_playing():
				return State.IDLE
	return state


#状态转换函数，进行状态的初始化
func transition_state(from: State, to: State)-> void:
	#if from in GROUND_STATES and to in GROUND_STATES:
		#print(coyote_timer.time_left)
		#print("coyote_timer.stop()")
		#coyote_timer.stop()
	match to:
		State.IDLE:
			animation_playerStates.play("idle")
			
		State.RUNING:
			animation_playerStates.play("runing")
			
		State.JUMPING:
			animation_playerStates.play("jumping")
			velocity.y = JUMP_SPEED
			coyote_timer.stop()
			jump_request_timer.stop()
			
		State.FALLING:
			animation_playerStates.play("falling")
			if from in GROUND_STATES:
				coyote_timer.set_wait_time(COYOTE_TIME)
				coyote_timer.start()
			
		State.LANDING:
			animation_playerStates.play("landing")
			
		State.WALL_SLIDING:
			animation_playerStates.play("wall_sliding")
			velocity = Vector2(500, 0) * -get_wall_normall_direction()
			
		State.WALL_JUMPING:
			animation_playerStates.play("jumping")
			var wall_normall_direction : int = get_wall_normall_direction()
			velocity = WALL_JUMP_SPEED
			velocity.x *= wall_normall_direction
			graphic_2d.scale.x = wall_normall_direction
			jump_request_timer.stop()
			
		State.ATTACK:
			animation_playerStates.play("attack")
		State.COMBO_ATTACK:
			animation_playerStates.play("combo_attack")
		State.CRITICAL_ATTACK:
			animation_playerStates.play("critical_attack")
	is_first_tick = true

	print(owner.name, 
		" [ %s ] << from %s to %s >> " % [
		Engine.get_physics_frames(),
		State.keys()[from] if from >= 0 else "<START>" ,
		State.keys()[to]
		],
		"velocity ",velocity
		)


#玩家输入进行移动
func move(gravity: float, delta: float)-> void:
	var acceleration : float = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	var direction = Input.get_axis("move_left","move_right")
	velocity.x = move_toward(velocity.x, RUN_SPEED_MAX * direction, acceleration * delta)#x方向移动
	velocity.y += gravity * delta#y方向移动
	if not is_zero_approx(direction):#翻转图像
		graphic_2d.scale.x = -1 if direction < 0.0 else 1 
	move_and_slide()

#忽略玩家输入的移动
func move_without_input(gravity: float, delta: float)-> void:
	var acceleration : float = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)#x方向移动
	velocity.y += gravity * delta#y方向移动
	move_and_slide()

#状态的物理帧处理
func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE:
			move(default_gravity, delta)
			
		State.RUNING:
			move(default_gravity, delta)
			
		State.JUMPING:
			move(0.0 if is_first_tick else default_gravity, delta)
			
		State.FALLING:
			move(default_gravity, delta)
			
		State.LANDING:
			move(default_gravity, delta)
			
		State.WALL_SLIDING:
			move_without_input(default_gravity / 1000.0, delta)
			
		State.WALL_JUMPING:
			move(0.0 if is_first_tick else default_gravity, delta)
			
		State.ATTACK:
			move_without_input(default_gravity, delta)
		State.COMBO_ATTACK:
			move_without_input(default_gravity, delta)
		State.CRITICAL_ATTACK:
			move_without_input(default_gravity, delta)
			
	is_first_tick = false











