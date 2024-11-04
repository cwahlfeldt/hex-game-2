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
	#SignalBus.selected_hex.connect(_on_hex_selected)
	#
	## Initialize the grid if needed
	#HexGridManager.initialize_grid({
		#"map_size": 5,
		#"holes_to_remove": 8,
		#"show_labels": true
	#})
	#var hex_grid = HexGridManager.get_grid()
	#var traversable_grid = HexGridManager.get_traversable_grid()
#
	#player = UnitManager.spawn_player(hex_grid[HexGridManager.player_start_index])
	#for _i in range(2):
		#var random_hex = traversable_grid[rng.randi_range(HexGridManager.map_size * 7, traversable_grid.size())]
		#UnitManager.spawn_enemy(random_hex)

#func _on_hex_selected(hex: Hex) -> void:
	#var current_unit = HexGridManager.get_current_unit()
	#if current_unit != null:
		#HexGridManager.move_unit(current_unit, hex)
