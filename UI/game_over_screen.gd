extends Control


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $Label


func _ready() -> void:
	hide()
	set_process_input(false)


func _input(event: InputEvent) -> void:
	get_window().set_input_as_handled()
	if animation_player.is_playing():
		return
	if(event is InputEvent or 
		event is InputEventMouseButton or
		event is InputEventJoypadButton):
		if event.is_pressed() and not event.is_echo():
			if Game.has_save():
				Game.load_game()
			else:
				Game.back_to_title()
			hide()
			label.set_visible_ratio(0.0)
			set_process_input(false)


func show_game_over()->void:
	animation_player.play("enter")
	set_process_input(true)
	show()

