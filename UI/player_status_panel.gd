extends HBoxContainer


@export var stats: Stats
@onready var health_box: TextureProgressBar = $VBoxContainer/HealthBox
@onready var ease_health_box: TextureProgressBar = $VBoxContainer/HealthBox/EaseHealthBox
@onready var energy_box: TextureProgressBar = $VBoxContainer/EnergyBox


func _ready() -> void:
	stats.health_changed.connect(_update_health_bar)
	_update_health_bar()
	stats.energy_changed.connect(_update_energy_bar)
	_update_energy_bar()


func _update_health_bar()->void:
	health_box.value = stats.health / float(stats.MAX_HEALTH)
	var tween:Tween = create_tween()
	tween.tween_property(ease_health_box, "value", health_box.value, 0.8).set_trans(Tween.TRANS_SINE)

func _update_energy_bar()->void:
	energy_box.value = stats.energy / float(stats.MAX_ENERGY)
