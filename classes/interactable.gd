class_name Interactable
extends Area2D


func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)

func interact()->void:
	print("DB ",self.name)
	#on_body_exited(body)#可以不使用，queue_free调用后on_body_exited仍有效
	#queue_free()

func on_body_entered(body: Player)->void:
	body.register_interact(self)

func on_body_exited(body: Player)->void:
	body.erase_interact(self)
