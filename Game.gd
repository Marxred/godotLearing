#自动加载。
#储存全局游戏参数
extends Node


#初始化变量
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect
@onready var player_stats: Stats = $PlayerStats
#引擎速度
@export var engine_time_scale: float = 1.0:
	set(v):
		Engine.set_time_scale(v)
		engine_time_scale = v
#淡入淡出参数
var fade_in_duration: float = 0.2
var fade_out_duration: float = 0.1

#game_state(内部数据)
#scene_state = {
					#"player":	[
									#[MAX_HEALTH, health, MAX_ENERGY, energy],
									#Vector2(玩家全局位置x分量, 玩家全局位置y分量),
									#direction
								#]
					#"curent_world":[
									#scene_path,
									#enemies_alive：[存活敌人对应场景树位置]
								#]
#}

#data(外部数据)
#data = {
	#"curent_world":	scene_path
	#"world_states":	{
						#scene_path: {
									#enemies_alive：Array[存活敌人对应场景树位置]
									#}
						#...
					#}
	#"player":	{
				#"state": [MAX_HEALTH, health, MAX_ENERGY, energy]
				#"position": [玩家全局位置x分量, 玩家全局位置y分量]
				#"direction": direction
				#}
#}
var world_states:Dictionary={}#游玩时的状态
#存档文件和路径
const SAV_PATH: String = "user://data.sav"##data.sav  :JSON格式游戏状态存档


#协程函数，调用需要使用await，直接调用则无视await tween.finished
func fade(final_val: float, duration: float)->void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", final_val, duration)
	await tween.finished

func _ready() -> void:
	pass


#改变场景
func change_scene_to(scene: String, entry_point: String)->void:
	var tree = get_tree()
	#淡入并暂停场景树
	tree.paused = true
	await fade(1.0, fade_in_duration)
	#收集旧场景状态
	var old_scene_name:String = tree.current_scene.scene_file_path
	world_states[old_scene_name] = tree.current_scene.state_to_dict()
	#切换新场景
	tree.change_scene_to_file(scene)
	await tree.tree_changed
	for entry_to:EntryPoint in tree.get_nodes_in_group("entry_points"):
		if entry_to.name == entry_point:
			var current_scene:Node = tree.current_scene
			current_scene.update_player([
							[player_stats.MAX_HEALTH, 
							player_stats.health, 
							player_stats.MAX_ENERGY, 
							player_stats.energy],
						entry_to.global_position,
						current_scene.player_2d.direction])
			break
	#加载新场景状态
	var new_scene_name:String = tree.current_scene.scene_file_path
	if new_scene_name in world_states:#是否是第一次进入场景
		tree.current_scene.state_from_dict(world_states[new_scene_name])
	
	#淡出并启动场景树
	tree.paused = false
	await fade(0.0, fade_out_duration)

#改变场景
func load_game()->void:
	#读取数据
	var file: FileAccess = FileAccess.open(SAV_PATH,FileAccess.READ)
	if not file:
		reload_current_scene()
	var json: String= file.get_as_text()
	var data: Dictionary = JSON.parse_string(json)
	if not data:
		print("DB ERROR data")
		return
	world_states = data.world_states
	file.close()
	
	#切换场景
	var tree = get_tree()
	#淡入并暂停场景树
	tree.paused = true
	await fade(1.0, fade_in_duration)
	
	#切换场景
	var scene_state = data_to_game_state(data)
	var load_scene:String = scene_state.curent_world[0]
	tree.change_scene_to_file(load_scene)
	await tree.tree_changed
	tree.current_scene.state_from_dict_new_test(scene_state)
	
	#淡出并启动场景树
	tree.paused = false
	await fade(0.0, fade_out_duration)


func data_to_game_state(data:Dictionary)->Dictionary:
	var load_scene_path:String = data.curent_world
	var player:Array = [data.player.state,
						Vector2(data.player.position[0]
								,data.player.position[1]),
						data.player.direction]
	var scene_state: Dictionary = {
		"player": player,
		"curent_world":[load_scene_path, 
						data.world_states[load_scene_path].enemies_alive]
		}
	return scene_state


func save_game()->void:
	var scene: World = get_tree().current_scene
	var scene_name: String = scene.scene_file_path
	var scene_state: Dictionary = scene.state_to_dict()

	world_states[scene_name] = scene_state

	var player: Dictionary = player_stats.to_dict()
	player["position"] = [scene.player_2d.global_position.x
						, scene.player_2d.global_position.y]
	player["direction"] = scene.player_2d.direction

	#当前加载的场景路径，当前场景状态，玩家状态
	var data:Dictionary ={
		"curent_world" = scene_name,
		"world_states" = world_states,
		"player" = player
	}
	var date_string: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(SAV_PATH, FileAccess.WRITE)
	file.store_string(date_string)



#player生命值耗尽后重启关卡
func reload_current_scene()->void:
	player_stats.health = player_stats.MAX_HEALTH
	load_game()


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("save"):#1
		save_game()
	if Input.is_action_pressed("load"):#2
		load_game()













