class_name StateMachine
extends Node

#与人物get_next_state配合使用,实现控制同一状态的重复进入
var ENTER_CURRENT_STATE_AGAIN:bool = false
#记录进入一个状态的时间
var state_time:float = 0.0
var current_state: int = -1:
	set(v):
		owner.transition_state(current_state, v)
		ENTER_CURRENT_STATE_AGAIN = false
		current_state = v
		state_time = 0.0


func _ready() -> void:
	await owner.ready
	current_state = 0

func _physics_process(delta: float) -> void:
	var next : int = owner.get_next_state(current_state)
	if next == current_state and !ENTER_CURRENT_STATE_AGAIN:
		pass
	else:
		current_state = next
	owner.tick_physics(current_state, delta)
	state_time += delta
