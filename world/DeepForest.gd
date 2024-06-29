extends World


func _on_boar_3_died() -> void:
	await get_tree().create_timer(1).timeout
	Game.end_game()
