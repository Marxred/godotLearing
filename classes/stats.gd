class_name Stats
extends Node

@export var MAX_HEALTH :int= 5
@onready var health: int= MAX_HEALTH:
	get: return health
	set(v):
		v = clamp(v, 0, MAX_HEALTH)
		if v == health:
			return
		else: health = v
