extends Node3D

func _ready() -> void:
	GameManager.initialize_game({
		"grid_size": 5,
		"holes_to_remove": 8,
		"enemy_count": 2
	})

	SignalBus.start_game.emit()
	
 
