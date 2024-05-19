extends CharacterBody2D


#初始化参数
var gravity : float = ProjectSettings.get("physics/2d/default_gravity")
var direction: float = 0.0
@export var JUMP_SPEED: float = -300.0
@export var RUN_SPEED_MAX : float= 180.0
const FLOOR_ACCELERATE_TIME : float = 0.1
const AIR_ACCELERATE_TIME : float = 0.02
var FLOOR_ACCELERATION : float = RUN_SPEED_MAX / FLOOR_ACCELERATE_TIME
var AIR_ACCELERATION : float = RUN_SPEED_MAX / AIR_ACCELERATE_TIME
const COYOTE_TIME: float = 0.1
const JUMP_REQUEST_TIME: float = 10.0#不能太小，会导致无法起跳；极大数无影响，极小数有影响
#var RUN_SPEED: float = 0

#初始化资源
@onready var sprite_player: Sprite2D = $Sprite_Player
@onready var animation_playerStates: AnimationPlayer = $Animation_PlayerStates
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		print("jump_request_timer.set_wait_time(JUMP_REQUEST_TIME) ")
		jump_request_timer.set_wait_time(JUMP_REQUEST_TIME)
		print("jump_request_timer.start()")
		jump_request_timer.start()
	if event.is_action_released("jump") and velocity.y < JUMP_SPEED /2.0:
		velocity.y = JUMP_SPEED /2.0


func _physics_process(delta: float) -> void:
#玩家移动设定
	var acceleration : float = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	#x方向移动
	direction = Input.get_axis("move_left","move_right")
	velocity.x = move_toward(velocity.x, RUN_SPEED_MAX * direction,
							acceleration * delta)
#	RUN_SPEED = RUN_SPEED + RUN_ACC
#	velocity.x = RUN_SPEED * direction
#	velocity.x = clamp(velocity.x, -RUN_SPEED_MAX, RUN_SPEED_MAX)
#	RUN_SPEED = abs(velocity.x)
#y方向移动
	velocity.y += gravity * delta

	var can_jump : bool = is_on_floor() or coyote_timer.time_left
	var should_jump : bool = can_jump and jump_request_timer.time_left
	if should_jump:
		velocity.y = JUMP_SPEED
		coyote_timer.stop()
		print("jump_request_timer.stop()")
		jump_request_timer.stop()

#动画播放
	if is_on_floor():
		if is_zero_approx(direction) and is_zero_approx(velocity.x):
			animation_playerStates.play("idle")
		else:
			animation_playerStates.play("runing")
	else:
		animation_playerStates.play("jumping")
	#翻转图像
	if not is_zero_approx(direction):
		sprite_player.set_flip_h(direction < 0)

	var was_on_floor = is_on_floor()
	move_and_slide()
#设置coyoteTimer
	if is_on_floor() != was_on_floor :
		if was_on_floor and not should_jump:
			coyote_timer.set_wait_time(COYOTE_TIME)
			coyote_timer.start()
		else:
			coyote_timer.stop()

	#if is_on_floor() != was_on_floor and not should_jump:
		#print("coyote_timer.wait_time ", coyote_timer.wait_time)
		#coyote_timer.wait_time = COYOTE_TIME
		#print("coyote_timer.wait_time ", coyote_timer.wait_time)
		#coyote_timer.start()
	#else:
		#print("coyote_timer.stop()")
		#coyote_timer.stop()
#输出
#	print("delta", delta," direction", direction, " velocity",velocity)
#	print("move_and_slide ",
#	move_and_slide()
#	)
