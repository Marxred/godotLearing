#
class_name InteractablePortal
extends Interactable

#要进入的场景
@export_file("*.tscn") var scene_to:String
#出现位置
@export var entry_point_name: String


func interact()->void:
	super()
	Game.change_scene_to(scene_to, entry_point_name)
