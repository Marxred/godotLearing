#自动加载。
#储存全局游戏参数
extends Node


#初始化变量
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect
@onready var player_stats: Stats = $PlayerStats
#调节引擎速度
@export var engine_time_scale: float = 1.0:
	set(v):
		Engine.set_time_scale(v)
		engine_time_scale = v
#淡入淡出参数
var fade_in_duration: float = 0.2
var fade_out_duration: float = 0.1
#当前场景绝对地址
var last_scene: String
#当前场景进入点
var last_entry_point: String
#世界状态 => {场景文件地址 => 场景状态。。。}
#				场景状态 => {enemies_alive：Array[存活敌人对应场景树位置]}
var world_states:Dictionary={}

#协程函数，调用需要使用await，直接调用则无视await tween.finished
func fade(final_val: float, duration: float)->void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", final_val, duration)
	await tween.finished

#改变场景
func change_scene_to(scene: String, entry_point: String)->void:
	last_entry_point = entry_point
	last_scene = scene
	var tree = get_tree()
	#淡入并暂停场景树
	tree.paused = true
	await fade(1.0, fade_in_duration)
	#收集旧场景状态
	var old_scene_name:String = tree.current_scene.scene_file_path\
									.get_basename()
	world_states[old_scene_name] = tree.current_scene.state_to_dict()
	#切换新场景
	tree.change_scene_to_file(scene)
	await tree.tree_changed
	for entry_to:EntryPoint in tree.get_nodes_in_group("entry_points"):
		if entry_to.name == entry_point:
			var current_scene:Node = tree.current_scene
			current_scene.update_player(\
					entry_to.global_position, entry_to.direction)
			break
	#加载新场景状态
	var new_scene_name:String = tree.current_scene.scene_file_path\
									.get_basename()
	if new_scene_name in world_states:#是否是第一次进入场景
		tree.current_scene.state_from_dict(world_states[new_scene_name])
	
	#淡出并启动场景树
	tree.paused = false
	await fade(0.0, fade_out_duration)

#player生命值耗尽后重启关卡
func reload_current_scene()->void:
	player_stats.health = player_stats.MAX_HEALTH
	change_scene_to(last_scene, last_entry_point)
