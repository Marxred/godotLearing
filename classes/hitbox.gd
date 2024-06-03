class_name HitBox
extends Area2D

signal hit(hurtbox: Hurtbox)


func _init() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(hurtbox: Hurtbox)->void:
	hit.emit(hurtbox)
	hurtbox.hurt.emit(self)
	print("[HIT] %s => %s" % [owner.name, hurtbox.owner.name])

