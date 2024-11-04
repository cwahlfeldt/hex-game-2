extends Node3D

var player: Player
var rng = RandomNumberGenerator.new()
# var hex_grid_manager: HexGridManager

func _ready() -> void:
	GameManager.initialize_game({
		"grid_size": 5,
		"holes_to_remove": 8,
		"enemy_count": 2
	})
	