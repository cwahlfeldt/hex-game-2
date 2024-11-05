extends Node3D

const PLAYER_SCENE = preload("res://scenes/Player/Player.tscn")
const ENEMY_SCENE = preload("res://scenes/Enemy/Enemy.tscn")

# Configuration
@export_group("Game Settings")
@export var grid_size: int = 5
@export var holes_to_remove = 8
@export var enemy_count: int = 2
@export var starting_player_health: int = 3

# Core managers and states
var unit_manager: UnitManager
var game_state: GameState = GameState.SETUP
var player: Player = null

enum GameState {
	SETUP,
	PLAYING,
	COMBAT,
	GAME_OVER
}

func initialize_game(config: Dictionary) -> void:
	_apply_configuration(config)

	HexGridManager.initialize_grid({
		"map_size": grid_size,
		"holes_to_remove": holes_to_remove,
		"show_labels": true
	})
	
	spawn_initial_units()
	game_state = GameState.PLAYING
	connect_signals()

func _apply_configuration(config: Dictionary) -> void:
	if config.has("map_size"):
		grid_size = config.grid_size
	if config.has("holes_to_remove"):
		holes_to_remove = config.holes_to_remove
	if config.has("enemy_count"):
		enemy_count = config.enemy_count

func spawn_initial_units() -> void:
	var grid = HexGridManager.get_grid()
	var traversable_grid = HexGridManager.get_traversable_grid()
	
	player = UnitManager.spawn_player(grid[HexGridManager.player_start_index])
	
	for i in enemy_count:
		var random_hex = traversable_grid[
			randi_range(HexGridManager.map_size * 7, traversable_grid.size())
		]
		UnitManager.spawn_enemy(random_hex)

func connect_signals() -> void:
	SignalBus.start_game.connect(_on_game_start)
	SignalBus.player_turn.connect(_on_player_turn)
	SignalBus.enemy_turn.connect(_on_enemy_turn)
	SignalBus.player_turn_end.connect(_on_player_turn_end)
	SignalBus.enemy_turn_end.connect(_on_enemy_turn_end)
	SignalBus.all_turns_end.connect(_on_all_turns_end)
	SignalBus.unit_turn_end.connect(_on_unit_turn_end)

func _on_game_start():
	game_state = GameState.PLAYING
	player.show_movement_range()
	for enemy in HexGridManager.get_enemies():
		enemy.show_movement_range()

# Turn Management
func _on_player_turn(unit: Player, hex):
	unit.clear_highlights()
	HexGridManager.move_unit(unit, hex)

func _on_player_turn_end(unit: Player):
	unit.show_movement_range()
	# var units_in_range = HexGridManager.get_units_in_attack_range(unit, 1)
	# print(units_in_range)

func _on_enemy_turn(unit: Enemy):
	unit.clear_highlights()
	HexGridManager.move_unit(unit, player.current_hex)

func _on_enemy_turn_end(unit: Enemy):
	# var units_in_range = HexGridManager.get_units_in_attack_range(unit, 1)
	# print(units_in_range)
	unit.show_movement_range()

func _on_unit_turn_end(unit: Unit):
	var units_in_range = HexGridManager.get_units_in_attack_range(unit, unit.atk_range)
	print(units_in_range, " of ", unit)
	# unit.show_movement_range()

func _on_all_turns_end(_units):
	pass
