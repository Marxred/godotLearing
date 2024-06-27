#世界节点，进行世界初始化，将世界状态转换为字典
class_name World
extends Node2D


@onready var map: TileMap = $map
@onready var player_camera: Camera2D = $Player2D/Player_camera
@onready var player_2d: Player = $Player2D


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
func update_player(pos: Vector2, direction: Player.Direction)->void:
	player_2d.global_position = pos
	player_2d.direction = direction
	player_camera.reset_smoothing()
	player_camera.force_update_scroll()

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
func state_from_dict(scene_state: Dictionary)->void:
	update_enemy_state(scene_state.enemies_alive)
	#for enemy in get_tree().get_nodes_in_group("enemies"):
		#var path : String = get_path_to(enemy)
		#if path not in scene_state.enemies_alive:
			#enemy.queue_free()

#更新敌人状态
func update_enemy_state(enemies_alive: Array)->void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var path : String = get_path_to(enemy)
		if path not in enemies_alive:
			enemy.queue_free()
