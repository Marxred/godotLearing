class_name StateMachine
extends Node


var current_state: int = -1:
	set(v):
		owner.transition_state(current_state, v)
		current_state = v


func _ready() -> void:
	print("current_state", current_state)
	await owner.ready
	current_state = 0
	print("current_state", current_state)
	#Engine.set_time_scale(0.5)


func _physics_process(delta: float) -> void:
	while true:
		var next : int = owner.get_next_state(current_state)
		if next == current_state:
			break
		current_state = next
	owner.tick_physics(current_state, delta)
