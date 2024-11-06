extends Node3D

const PLAYER_SCENE = preload("res://scenes/Player/Player.tscn")
const ENEMY_SCENE = preload("res://scenes/Enemy/Enemy.tscn")

# Configuration
var grid_size: int = 5
var holes_to_remove = 8
var enemy_count: int = 2
var starting_player_health: int = 3
var selected_hex: Hex = null


# Core managers and states
var unit_manager: UnitManager
var game_state: GameState = GameState.SETUP
var player: Player = null

enum GameState {
	# Game states
	SETUP,
	IDLE,
	GAME_OVER,

	# Turn states
	PLAYERS_IDLE,
	PLAYER_MOVE,
	ENEMY_IDLE,
	ENEMY_MOVE,
	PLAYER_ATTACK,
	ENEMY_ATTACK,
}

func initialize_game(config: Dictionary) -> void:
	game_state = GameState.SETUP

	_apply_configuration(config)
	_connect_signals()

	HexGridManager.initialize_grid({
		"map_size": grid_size,
		"holes_to_remove": holes_to_remove,
		"show_labels": true
	})
	
	# spawned units are added to the turn queue automagically
	_spawn_initial_units()

func _apply_configuration(config: Dictionary) -> void:
	if config.has("map_size"):
		grid_size = config.grid_size
	if config.has("holes_to_remove"):
		holes_to_remove = config.holes_to_remove
	if config.has("enemy_count"):
		enemy_count = config.enemy_count

func _spawn_initial_units() -> void:
	var grid = HexGridManager.get_grid()
	var traversable_grid = HexGridManager.get_traversable_grid()
	
	player = UnitManager.spawn_player(grid[HexGridManager.player_start_index])
	
	for i in enemy_count:
		var random_hex = traversable_grid[
			randi_range(HexGridManager.map_size * 7, traversable_grid.size())
		]
		UnitManager.spawn_enemy(random_hex)

func _connect_signals() -> void:
	SignalBus.start_game.connect(_on_game_start)
	# SignalBus.player_turn.connect(_on_player_turn)
	# SignalBus.enemy_turn.connect(_on_enemy_turn)
	# SignalBus.player_turn_end.connect(_on_player_turn)
	# SignalBus.enemy_turn_end.connect(_on_enemy_turn)
	# SignalBus.all_turns_end.connect(_on_all_turns_end)
	SignalBus.turn_start.connect(_on_turn_start)
	SignalBus.turn_end.connect(_on_turn_end)
	SignalBus.selected_hex.connect(_on_selected_hex)

func _on_game_start():
	print("Game Start\n")
	for unit in UnitManager.get_all_units():
		unit.show_movement_range()
		
	game_state = GameState.PLAYERS_IDLE

	SignalBus.turn_start.emit(player)
	SignalBus.player_turn.emit(player, null)

func _play(unit, hex) -> void:
	if selected_hex == null:
		print("No hex selected \n")
		return

	match game_state:
		GameState.PLAYER_MOVE:
			UnitManager.move_unit(unit, hex)
			game_state = GameState.PLAYER_ATTACK

		GameState.PLAYER_ATTACK:
			var units_in_attack_range = UnitManager.get_units_in_attack_range(unit, unit.atk_range)
			# if units_in_attack_range.size() == 0:
			game_state = GameState.ENEMY_MOVE

		GameState.ENEMY_MOVE:
			UnitManager.move_unit(unit, hex)
			game_state = GameState.ENEMY_ATTACK

		GameState.ENEMY_ATTACK:
			var units_in_attack_range = UnitManager.get_units_in_attack_range(unit, unit.atk_range)
			if units_in_attack_range.size() == 0:
				print("No units in attack range \n")
			game_state = GameState.PLAYER_MOVE

# Turn Management
# func _on_player_turn(unit: Player):
# 	_play(unit, selected_hex)

# func _on_enemy_turn(unit: Enemy):
# 	_play(unit, selected_hex)

func _on_turn_start(unit: Unit):
	if selected_hex != null:
		unit.clear_highlights()
		_play(unit, selected_hex)

func _on_turn_end(unit: Unit):
	unit.show_movement_range()
	_play(unit, selected_hex)

# Triggers the players turn
func _on_selected_hex(hex: Hex):
	var unit = TurnManager.get_current()
	selected_hex = hex
	if unit.type == Unit.UNIT_TYPE.PLAYER:
		game_state = GameState.PLAYER_MOVE
		SignalBus.player_turn.emit(unit)
		SignalBus.turn_start.emit(unit)
	
