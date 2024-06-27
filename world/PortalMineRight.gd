extends InteractablePortal

func _ready() -> void:
	entry_point_name = get_child(get_child_count() - 1).name
