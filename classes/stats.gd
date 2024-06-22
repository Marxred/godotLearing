class_name Stats
extends Node

signal health_changed
signal energy_changed

@export var MAX_HEALTH :int= 5
@onready var health: int= MAX_HEALTH:
	get: return health
	set(v):
		v = clamp(v, 0, MAX_HEALTH)
		if v == health:
			return
		else: health = v
		health_changed.emit()

@export var MAX_ENERGY : float = 3
@onready var energy: float = MAX_ENERGY:
	get: return energy
	set(v):
		v = clamp(v, 0.0, MAX_ENERGY)
		if v == energy:
			return
		else: energy = v
		energy_changed.emit()
