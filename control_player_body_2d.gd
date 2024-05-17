extends CharacterBody2D


#初始化参数
var gravity : float = ProjectSettings.get("physics/2d/default_gravity")
var direction:= Input.get_axis("move_left","move_right")
@export var SPEED_JUMP: float = 300
@export var RUN_ACC : float = 50.0
@export var RUN_SPEED_MAX = 180.0
var RUN_SPEED: float = 0

#初始化资源
@onready var sprite_Player: Sprite2D = $Sprite_Player
@onready var animation_PlayerStates: AnimationPlayer = $Animation_PlayerStates


func _physics_process(delta: float) -> void:
#玩家移动设定
	#x方向移动
	direction = Input.get_axis("move_left","move_right")
#	velocity.x = RUN_SPEED_MAX * direction
	RUN_SPEED = RUN_SPEED + RUN_ACC
	velocity.x = RUN_SPEED * direction
	velocity.x = clamp(velocity.x, -RUN_SPEED_MAX, RUN_SPEED_MAX)
	RUN_SPEED = abs(velocity.x)
#y方向移动
	velocity.y += gravity * delta

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -SPEED_JUMP

#动画播放
	if is_on_floor():
		if is_zero_approx(direction):
			animation_PlayerStates.play("idle")
		else:
			animation_PlayerStates.play("runing")
	else:
		animation_PlayerStates.play("jumping")
	if not is_zero_approx(direction):
		sprite_Player.set_flip_h(direction < 0)

#输出
	print("delta", delta," direction", direction, " velocity",velocity)
	print("move_and_slide ",
	move_and_slide()
	)
