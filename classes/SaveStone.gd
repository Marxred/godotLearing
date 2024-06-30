extends Interactable


@onready var sparkle: AnimationPlayer = $sparkle


func interact()->void:
	super()
	Game.save_game()
	sparkle.play("activated")
	self.monitoring = false

