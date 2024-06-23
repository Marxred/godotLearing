class_name Enemy
extends CharacterBody2D

enum Direction{
	LEFT = -1,
	MIDDLE = 0,
	RIGHT = 1,
}

#初始化变量
var default_gravity : float = ProjectSettings.get("physics/2d/default_gravity")
@export var max_speed: float = 200.0
var acceration: float = max_speed / 0.2
@export var direction := Direction.RIGHT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphic.scale.x = direction
#初始化资源
@onready var graphic: Node2D = $Graphic
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
