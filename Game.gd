#自动加载。
#储存全局游戏参数
extends Node


#初始化变量
@onready var game_over_screen: Control = $UI/GameOverScreen
@onready var vignette: CanvasLayer = $Vignette
@onready var ui: CanvasLayer = $UI
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
var first_scene: String =  "res://world/Forest.tscn"
var title: String = "res://UI/title_screen.tscn"

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

#scene_state2 = {
					#"player":	{
									#stats:[MAX_HEALTH, health, MAX_ENERGY, energy],
									#position:Vector2(玩家全局位置x分量, 玩家全局位置y分量),
									#direction:direction
								#
								# }
					#"world_state":{
									#scene_path: String
									#enemies_alive：[存活敌人对应场景树位置]
								#}
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
	vignette.visible = false
	ui.visible = false

enum CHANGE_MODE{
	ENTRY,
	LOAD,
	NEW,
}

# scene_state
func total_change2(change_mode: CHANGE_MODE,scene_state2: Dictionary = {}, entry_point: String = "")->void:
	#淡入并暂停场景树
	var tree = get_tree()
	tree.paused = true
	await fade(1.0, fade_in_duration)

	var new_scene: String = scene_state2.world_state.scene_path

	match change_mode:
		CHANGE_MODE.ENTRY:
			# CHANGE_MODE.ENTRY 只使用scene_state.world_state 即scene_path, 根据新场景信息构造scene_state
			if entry_point:
				print("Invalid EntryPoint")
				back_to_title()
			#收集旧场景状态
			var old_scene_name:String = tree.current_scene.scene_file_path
			world_states[old_scene_name] = tree.current_scene.state_to_dict()
			#切换新场景
			tree.change_scene_to_file(new_scene)
			await tree.tree_changed
	
			for entry_to:EntryPoint in tree.get_nodes_in_group("entry_points"):
				if entry_to.name == entry_point:
					scene_state2.player.stat = player_stats.to_dict().state
					scene_state2.player.position = entry_to.global_position
					scene_state2.player.direction = entry_to.direction
					break
			#加载新场景状态
			if new_scene in world_states:
				scene_state2.world_state = {
												"enemies_alive": world_states[new_scene].enemies_alive
										}
				tree.current_scene.state_from_dict_new_test(scene_state2)
			else:#第一次进入场景
					tree.current_scene.update_player(scene_state2.player)

		CHANGE_MODE.LOAD:
			# load 使用scene_state
			if scene_state2:
				print("Invalid LOAD_DATA")
				back_to_title()
				#切换场景
			tree.change_scene_to_file(new_scene)
			await tree.tree_changed
			tree.current_scene.state_from_dict_new_test(scene_state2)

		CHANGE_MODE.NEW:
			get_tree().change_scene_to_file(first_scene)

	#淡出并启动场景树
	tree.paused = false
	await fade(0.0, fade_out_duration)


#改变场景 world  to world
func change_scene_to(scene: String, entry_point: String)->void:
	#淡入并暂停场景树
	var tree = get_tree()
	tree.paused = true
	await fade(1.0, fade_in_duration)
	#收集旧场景状态
	var old_scene_name:String = tree.current_scene.scene_file_path
	world_states[old_scene_name] = tree.current_scene.state_to_dict()
	#切换新场景
	tree.change_scene_to_file(scene)
	await tree.tree_changed
	var player:Array
	for entry_to:EntryPoint in tree.get_nodes_in_group("entry_points"):
		if entry_to.name == entry_point:
			player = [
							[player_stats.MAX_HEALTH, 
							player_stats.health, 
							player_stats.MAX_ENERGY, 
							player_stats.energy],
						entry_to.global_position,
						entry_to.direction]
			break
	#加载新场景状态
	if not scene in world_states:#第一次进入场景
		tree.current_scene.update_player(player)
	else:
		var test: Dictionary = {"player": player,
								"curent_world":[
									scene,
									world_states[scene].enemies_alive
								]}
		tree.current_scene.state_from_dict_new_test(test)
	#淡出并启动场景树
	tree.paused = false
	await fade(0.0, fade_out_duration)

#改变场景 any to world
func load_game()->void:
	#读取数据
	var file: FileAccess = FileAccess.open(SAV_PATH,FileAccess.READ)
	if not file:
		back_to_title()
	var json: String= file.get_as_text()
	var data: Dictionary = JSON.parse_string(json)
	if not data:
		print("DB ERROR data")
		return
	world_states = data.world_states
	file.close()
	
	#切换场景	接收上面的 data 转换为 scene_state
	var scene_state = data_to_game_state(data)
	var tree = get_tree()
	#淡入并暂停场景树
	tree.paused = true
	await fade(1.0, fade_in_duration)
	
	#切换场景
	var load_scene:String = scene_state.curent_world[0]
	tree.change_scene_to_file(load_scene)
	await tree.tree_changed
	tree.current_scene.state_from_dict_new_test(scene_state)
	
	vignette.visible = true
	ui.visible = true
	
	#淡出并启动场景树
	tree.paused = false
	await fade(0.0, fade_out_duration)
 
# title to first world
func new_game()->void:
	#切换场景
	var tree = get_tree()
	#淡入并暂停场景树
	tree.paused = true
	await fade(1.0, fade_in_duration)
	
	get_tree().change_scene_to_file(first_scene)
	
	vignette.visible = true
	ui.visible = true
	
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
	#game_over_screen.visible = true
	#await load_game()
	#player_stats.health = player_stats.MAX_HEALTH
	#game_over_screen.visible = false
	game_over_screen.show_game_over()


# world to title
func back_to_title()->void:
	#切换场景
	var tree = get_tree()
	#淡入并暂停场景树
	tree.paused = true
	await fade(1.0, fade_in_duration)
	
	get_tree().change_scene_to_file(title)
	
	vignette.visible = false
	ui.visible = false
	
	#淡出并启动场景树
	tree.paused = false
	await fade(0.0, fade_out_duration)

func has_save()->bool:
	return FileAccess.file_exists(SAV_PATH)

func end_game():
	get_tree().change_scene_to_file("res://UI/game_end_screen.tscn")









