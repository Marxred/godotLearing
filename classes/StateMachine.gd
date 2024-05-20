class_name StateMachine
extends Node

@export var engine_time_scale: float = 1
var current_state: int = -1:
	set(v):
		#print("state from ",owner.State.find_key(current_state)," to ", owner.State.find_key(v))
		owner.transition_state(current_state, v)
		current_state = v


func _ready() -> void:
	await owner.ready
	current_state = 0
	Engine.set_time_scale(engine_time_scale)


func _physics_process(delta: float) -> void:
	while true:
		var next : int = owner.get_next_state(current_state)
		if next == current_state:
			break
		current_state = next
	owner.tick_physics(current_state, delta)
