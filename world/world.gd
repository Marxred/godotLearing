#世界节点，进行世界初始化，将世界状态转换为字典
class_name World
extends Node2D


@onready var map: TileMap = $map
@onready var player_camera: Camera2D = $Player2D/Player_camera
@onready var player_2d: Player = $Player2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Game.back_to_title()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#add_to_group("Forest")
	#设置摄像机状态
	var mapBound: Rect2i = map.get_used_rect().grow(-1)
	var tileSize: Vector2i = map.tile_set.tile_size
	player_camera.limit_top = mapBound.position.y * tileSize.y
	player_camera.limit_bottom = mapBound.end.y * tileSize.y
	player_camera.limit_left = mapBound.position.x * tileSize.x
	player_camera.limit_right = mapBound.end.x * tileSize.x
	player_camera.reset_smoothing()
	print("DB ",player_camera.limit_top," ",
			player_camera.limit_bottom," ",
			player_camera.limit_left," ",
			player_camera.limit_right)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#再次进入世界时根据pos，direction创建玩家状态
func update_player(player:Array)->void:
	Game.player_stats.MAX_HEALTH = player[0][0]
	Game.player_stats.health = player[0][1]
	Game.player_stats.MAX_ENERGY = player[0][2]
	Game.player_stats.energy = player[0][3]
	player_2d.global_position = player[1]
	player_2d.direction = player[2]
	player_camera.reset_smoothing()
	player_camera.force_update_scroll()

#更新敌人状态
func update_enemy_state(enemies_alive: Array)->void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var path : String = get_path_to(enemy)
		if path not in enemies_alive:
			enemy.queue_free()


#以字典形式储存世界状态
func state_to_dict()->Dictionary:
	var enemies_alive:=[]
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var path : String = get_path_to(enemy)
		enemies_alive.append(path)
	return {
		"enemies_alive" = enemies_alive
		}

#根据世界状态字典配置场景状态
func _state_from_dict(scene_state: Dictionary)->void:
	update_enemy_state(scene_state.enemies_alive)
	#for enemy in get_tree().get_nodes_in_group("enemies"):
		#var path : String = get_path_to(enemy)
		#if path not in scene_state.enemies_alive:
			#enemy.queue_free()

#根据世界状态字典配置场景状态
func state_from_dict_new_test(scene_state: Dictionary)->void:
	#var enemies_alive:Array = scene_state.curent_world[1]
	#var player_val:Array = scene_state.player
	#update_enemy_state(enemies_alive)
	#update_player(player_val)
	
	update_enemy_state(scene_state.curent_world[1])
	update_player(scene_state.player)

#scene_state{
					#"player":	[
									#[MAX_HEALTH, health, MAX_ENERGY, energy]
									#[玩家全局位置x分量, 玩家全局位置y分量]
									#direction
								#]
					#"curent_world":[
									#scene_name
									#enemies_alive：[存活敌人对应场景树位置]
								#]
#}


#data => {
# "world_states" => 世界状态
# "player" => player
#}
#player => {
#			"state" => [MAX_HEALTH, health, MAX_ENERGY, energy]
#			"position" => [玩家全局位置x分量, 玩家全局位置y分量]
#			"direction" = scene.player.direction
#}
