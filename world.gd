extends Node2D


@onready var floor: TileMap = $floor
@onready var player_camera: Camera2D = $CharacterBody2D/Player_camera


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mapBound: Rect2i = floor.get_used_rect()
	var tileSize: Vector2i = floor.tile_set.tile_size
	player_camera.limit_top = mapBound.position.y * tileSize.y
	player_camera.limit_bottom = mapBound.end.y * tileSize.y
	player_camera.limit_left = mapBound.position.x * tileSize.x
	player_camera.limit_right = mapBound.end.x * tileSize.x
	player_camera.reset_smoothing()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
