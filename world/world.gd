extends Node2D

@export var engine_time_scale: float = 1
@onready var map: TileMap = $map
@onready var player_camera: Camera2D = $Player2D/Player_camera


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mapBound: Rect2i = map.get_used_rect().grow(-1)
	var tileSize: Vector2i = map.tile_set.tile_size
	player_camera.limit_top = mapBound.position.y * tileSize.y
	player_camera.limit_bottom = mapBound.end.y * tileSize.y
	player_camera.limit_left = mapBound.position.x * tileSize.x
	player_camera.limit_right = mapBound.end.x * tileSize.x
	player_camera.reset_smoothing()
	print(player_camera.limit_top," ",
		player_camera.limit_bottom," ",
		player_camera.limit_left," ",
		player_camera.limit_right)
	Engine.set_time_scale(engine_time_scale)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
