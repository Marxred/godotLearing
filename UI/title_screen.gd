extends Control


@export var bgm: AudioStream


@onready var v: VBoxContainer = $V
@onready var new_game_button: Button = $V/NewGame
@onready var load_game_button: Button = $V/LoadGame
@onready var exit_game_button: Button = $V/ExitGame

func _ready() -> void:
	new_game_button.pressed.connect(new_game)
	load_game_button.pressed.connect(load_game)
	exit_game_button.pressed.connect(exit_game)
	load_game_button.disabled = not Game.has_save()
	
	SoundManager.setup_ui_sounds(self)
	if bgm:
		SoundManager.play_bgm(bgm)

func new_game()->void:
	Game.new_game()


func load_game()->void:
	Game.load_game()


func exit_game()->void:
	get_tree().quit()

