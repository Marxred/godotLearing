#进入点，与传送门一起使用，设为传送门节点的子节点。
#上个场景的portal的entry_point属性连接下一个场景的entry_point
class_name EntryPoint
extends Marker2D

#决定加载场景时，玩家的朝向
@export var direction:= Player.Direction.RIGHT

#将所有EntryPoint加入entry_points组
func _ready() -> void:
	add_to_group("entry_points")
