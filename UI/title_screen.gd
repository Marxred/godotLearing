extends Control


@onready var v: VBoxContainer = $V
@onready var new_game_button: Button = $V/NewGame
@onready var load_game_button: Button = $V/LoadGame
@onready var exit_game_button: Button = $V/ExitGame

func _ready() -> void:
	new_game_button.pressed.connect(new_game)
	load_game_button.pressed.connect(load_game)
	exit_game_button.pressed.connect(exit_game)
	load_game_button.disabled = not Game.has_save()
	for button:Button in v.get_children():
		button.mouse_entered.connect(button.grab_focus)

func new_game()->void:
	Game.new_game()


func load_game()->void:
	Game.load_game()


func exit_game()->void:
	get_tree().quit()

