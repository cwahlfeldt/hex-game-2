extends Node3D

const PLAYER_SCENE = preload("res://scenes/Player/Player.tscn")
const ENEMY_SCENE = preload("res://scenes/Enemy/Enemy.tscn")

# Configuration
var grid_size: int = 5
var holes_to_remove = 8
var enemy_count: int = 2
var starting_player_health: int = 3
var selected_hex: Hex = null
var attack_hexes: Array[Hex] = []


# Core managers and states
var unit_manager: UnitManager
var current_state: GameState = GameState.SETUP
var player: Player = null

enum GameState {
	# Game states
	SETUP,
	IDLE,
	GAME_OVER,

	# Player states
	PLAYER_SELECT,
	PLAYER_MOVE,
	PLAYER_ATTACK,
	PLAYER_CAN_ATTACK,
	PLAYER_TAKE_DAMAGE,

	# Enemy states
	ENEMY_IDLE,
	ENEMY_TURN,
	ENEMY_MOVE,
	ENEMY_ATTACK,
	ENEMY_CAN_ATTACK,
	ENEMY_TAKE_DAMAGE
}

func initialize_game(config: Dictionary) -> void:
	current_state = GameState.SETUP

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
	SignalBus.unit_moved.connect(_on_unit_moved)
	SignalBus.turn_end.connect(_on_turn_end)
	SignalBus.selected_hex.connect(_on_selected_hex)

func _on_game_start() -> void:
	print("Game Starting...")
	_change_state(GameState.PLAYER_SELECT)

func _on_unit_moved(unit: Unit) -> void:
	# Check if unit can attack after moving
	unit.current_hex.unhighlight()

	if current_state != GameState.PLAYER_ATTACK:
		SignalBus.turn_end.emit(unit)

func _on_attack_completed(unit: Unit) -> void:
	SignalBus.turn_end.emit(unit)

func _on_turn_end(_unit: Unit) -> void:
	selected_hex = null

	var next_unit = TurnManager.get_next()
	if not next_unit:
		return
	TurnManager.next_turn()
	
	if next_unit.type == Unit.UNIT_TYPE.PLAYER:
		_change_state(GameState.PLAYER_SELECT)
	else:
		_change_state(GameState.ENEMY_TURN)

func _change_state(new_state: GameState) -> void:
	var old_state = current_state
	current_state = new_state
	print("State changed from ", GameState.keys()[old_state], " to ", GameState.keys()[new_state])
	
	match current_state:
		GameState.PLAYER_SELECT:
			_handle_player_select()

		GameState.PLAYER_MOVE:
			_handle_player_movement()
		
		GameState.PLAYER_CAN_ATTACK:
			_handle_player_can_attack()
		
		GameState.PLAYER_ATTACK:
			_handle_player_attack()
		
		GameState.ENEMY_TURN:
			_handle_enemy_turn()
		
		GameState.GAME_OVER:
			print("Game Over!")

# Signal handlers for game events
func _on_selected_hex(hex: Hex) -> void:
	selected_hex = hex
	
	if current_state != GameState.PLAYER_SELECT and current_state != GameState.PLAYER_CAN_ATTACK:
		return
		
	var current_unit = TurnManager.get_current()
	if not current_unit or current_unit.type != Unit.UNIT_TYPE.PLAYER:
		return
	
	if current_state == GameState.PLAYER_CAN_ATTACK:
		_change_state(GameState.PLAYER_ATTACK)
	else:
		_change_state(GameState.PLAYER_MOVE)

# State handlers
func _handle_player_select() -> void:
	var current_unit = TurnManager.get_current()
	if current_unit:
		current_unit.show_movement_range()
	
	var units_in_range = UnitManager.get_units_in_attack_range(current_unit, current_unit.atk_range)

	if not units_in_range.is_empty():
		var hexes_can_attack_on = HexGridManager.get_reachable_overlapping_neighbors(current_unit, units_in_range[0])
		for hex in hexes_can_attack_on:
			hex.highlight('g')
		_change_state(GameState.PLAYER_CAN_ATTACK)

func _handle_player_movement() -> void:
	var current_unit = TurnManager.get_current()
	if not current_unit or not selected_hex:
		_change_state(GameState.PLAYER_SELECT)
		return
	
	var target_hex = HexGridManager.find_target_hex(current_unit.current_hex, selected_hex, current_unit)
	current_unit.clear_highlights()
	target_hex.highlight('b')
	UnitManager.move_unit(current_unit, selected_hex)

func _handle_player_can_attack() -> void:
	var current_unit = TurnManager.get_current()
	
	if not current_unit:
		return
	
	if current_unit.type != Unit.UNIT_TYPE.PLAYER:
		return


func _handle_player_attack() -> void:
	var current_unit = TurnManager.get_current()
	
	if not current_unit:
		return
	
	if current_unit.type != Unit.UNIT_TYPE.PLAYER:
		return

	# var target_hex = HexGridManager.find_target_hex(current_unit.current_hex, selected_hex, current_unit)
	# current_unit.clear_highlights()
	# target_hex.highlight('b')
	UnitManager.move_unit(current_unit, selected_hex)
	print("Attacking...")

	# _change_state(GameState.PLAYER_SELECT)
	   
	# var units_in_range = UnitManager.get_units_in_attack_range(current_unit, current_unit.atk_range)
	# if units_in_range.is_empty():
	# 	SignalBus.turn_end.emit(current_unit)
	# 	return


func _handle_enemy_turn() -> void:
	var current_unit = TurnManager.get_current()

	if not current_unit or current_unit.type == Unit.UNIT_TYPE.PLAYER:
		_change_state(GameState.PLAYER_SELECT)
		return

	var target_hex = HexGridManager.find_target_hex(current_unit.current_hex, player.current_hex, current_unit)

	# show where its going
	await get_tree().create_timer(0.2).timeout
	target_hex.highlight('r')
	
	# Simple AI: Move towards player if not in attack range
	var units_in_range = UnitManager.get_units_in_attack_range(current_unit, current_unit.atk_range)
	
	if not units_in_range.is_empty():
		# Attack if in range
		var target = units_in_range[0]
		target.take_damage(current_unit.attack_power)
		SignalBus.attack_completed.emit(current_unit)
	else:
		# Move towards player
		UnitManager.move_unit(current_unit, player.current_hex)
