extends CharacterBody2D


enum State{
	IDLE,
	RUNING,
	JUMPING,
	FALLING,
	LANDING,
}
const GROUND_STATES : Array[State] =[State.IDLE, State.RUNING, State.LANDING]
const FLOOR_ACCELERATE_TIME : float = 0.1
const AIR_ACCELERATE_TIME : float = 0.02
const COYOTE_TIME: float = 0.1
const JUMP_REQUEST_TIME: float = 0.2#不能太小，会导致无法起跳；极大数无影响，极小数有影响

#初始化参数
@export var JUMP_SPEED: float = -300.0
@export var RUN_SPEED_MAX : float= 180.0
var default_gravity : float = ProjectSettings.get("physics/2d/default_gravity")
var is_first_tick: bool = false
var FLOOR_ACCELERATION : float = RUN_SPEED_MAX / FLOOR_ACCELERATE_TIME
var AIR_ACCELERATION : float = RUN_SPEED_MAX / AIR_ACCELERATE_TIME

#初始化资源
@onready var sprite_player: Sprite2D = $Sprite_Player
@onready var animation_playerStates: AnimationPlayer = $Animation_PlayerStates
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.set_wait_time(JUMP_REQUEST_TIME)
		jump_request_timer.start()
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_SPEED /2.0:
			velocity.y = JUMP_SPEED /2.0


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
		
	is_first_tick = false


#玩家移动设定
func move(gravity: float, delta: float)-> void:
	var acceleration : float = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	var direction = Input.get_axis("move_left","move_right")
	velocity.x = move_toward(velocity.x, RUN_SPEED_MAX * direction, acceleration * delta)#x方向移动
	velocity.y += gravity * delta#y方向移动
	if is_first_tick:
		print(velocity.y)
	
	if not is_zero_approx(direction):#翻转图像
		sprite_player.set_flip_h(direction < 0)
#
	#print("delta", delta," direction", direction, " velocity",velocity)#输出
	#print("move_and_slide ",
	#move_and_slide()
	#)
	move_and_slide()


#状态变换
func get_next_state(state: State)-> State:
	var can_jump : bool = is_on_floor() or coyote_timer.time_left
	var should_jump : bool = can_jump and jump_request_timer.time_left
	if should_jump: return State.JUMPING
	var direction: float = Input.get_axis("move_left","move_right")
	var is_still : bool = is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if not is_on_floor():
				return State.FALLING
			if not is_still:
				return State.RUNING
			
		State.RUNING:
			if not is_on_floor():
				return State.FALLING
			if is_still:
				return State.IDLE
			
		State.JUMPING:
			if velocity.y >= 0:
				return State.FALLING
			
		State.FALLING:
			if is_on_floor():
				return State.LANDING
			
		State.LANDING:
			if not animation_playerStates.is_playing() or not is_still:
				return State.IDLE
	
	return state


#状态实现
func transition_state(from: State, to: State)-> void:
	if from in GROUND_STATES and to in GROUND_STATES:
		coyote_timer.stop()
	
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
	
	is_first_tick = true









