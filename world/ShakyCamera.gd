extends Camera2D


var strength: float = 0
@export var recovery_speed: float = 30

# Called when the node enters the scene tree for the first time.
func _ready():
	Game.camera_should_shake.connect(
		func (amount:float):
			strength += amount
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	offset = Vector2(
		randf_range(-strength, +strength),
		randf_range(-strength, +strength)
	)
	strength = move_toward(strength, 0.0, delta* recovery_speed)
	
