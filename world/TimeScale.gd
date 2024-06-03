extends Node

func _ready() -> void:
	await owner.ready
	Engine.set_time_scale(owner.engine_time_scale)
