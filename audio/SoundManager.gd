class_name SoundManagerTest
extends Node


enum BUS{ MASTER, SFX, BGM}

@onready var sfx: Node2D = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

func play_sfx(sfx_name:String)->void:
	var player:= sfx.get_node(sfx_name) as AudioStreamPlayer
	if not player:
		return
	player.play()


func play_bgm(stream: AudioStream)->void:
	if bgm_player.stream == stream and bgm_player.is_playing():
		return
	bgm_player.stream = stream
	bgm_player.play()


func setup_ui_sounds(node:Node)->void:
	var button: Button = node as Button
	if button:
		button.pressed.connect(play_sfx.bind("UIPress"))
		button.focus_entered.connect(play_sfx.bind("UIFocus"))
		button.mouse_entered.connect(button.grab_focus)

	var slider:= node as Slider
	if slider:
		slider.value_changed.connect(play_sfx.bind("UIPress").unbind(1))
		slider.focus_entered.connect(play_sfx.bind("UIFocus"))
		slider.mouse_entered.connect(slider.grab_focus)

	for child in node.get_children():
		setup_ui_sounds(child)

func get_volume(bus_index: int)->float:
	var volume = AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(volume)

func set_volume(bus_index: int, volume: float)->void:
	volume = linear_to_db(volume)
	AudioServer.set_bus_volume_db(bus_index, volume)
	
	
	
	
