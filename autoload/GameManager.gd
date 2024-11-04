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

var _current_attackable_units: Array[Unit] = []
var _waiting_for_attack: bool = false

enum GameState {
	SETUP,
	PLAYING,
	COMBAT,
	GAME_OVER
}

# Combat tracking
var _units_in_combat_range: Dictionary = {}  # Unit -> Array[Unit] mapping

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
	
	player = UnitManager.spawn_player(
		grid[HexGridManager.player_start_index]
	)
	
	for i in enemy_count:
		var random_hex = traversable_grid[
			randi_range(HexGridManager.map_size * 7, traversable_grid.size())
		]
		UnitManager.spawn_enemy(random_hex)

func connect_signals() -> void:
	SignalBus.selected_hex.connect(_on_hex_selected)
	SignalBus.player_turn.connect(_on_player_turn)
	SignalBus.enemy_turn.connect(_on_enemy_turn)
	SignalBus.player_turn_end.connect(_on_player_turn_end)
	SignalBus.enemy_turn_end.connect(_on_enemy_turn_end)
	SignalBus.all_turns_end.connect(_on_all_turns_end)
	SignalBus.unit_died.connect(_on_unit_died)
	SignalBus.combat_started.connect(_on_combat_started)
	SignalBus.combat_ended.connect(_on_combat_ended)

# Combat System
func get_units_in_range(unit: Unit) -> Array[Unit]:
	var attackable_units: Array[Unit] = []
	var hexes_in_range = get_hexes_in_attack_range(unit)
	
	for hex in hexes_in_range:
		if HexGridManager.has_units(hex):
			for target in HexGridManager._hex_units[hex]:
				if target.type != unit.type:  # Different team
					attackable_units.append(target)
	
	return attackable_units

func get_hexes_in_attack_range(unit: Unit) -> Array[Hex]:
	var results: Array[Hex] = []
	var attack_range = 1  # Default melee range
	
	# Adjust range based on unit type
	if unit.type == Unit.UNIT_TYPE.GRUNT:
		attack_range = 2  # Grunts have longer range
	
	for hex in HexGridManager._grid:
		if not hex.traversable:
			continue
		
		var path = HexGridManager.find_path(unit.current_hex.index, hex.index)
		# Remove first and last elements to get true path length
		var true_path = path.slice(1, -1)
		if true_path.size() <= attack_range:
			results.append(hex)
	
	return results

func check_combat_after_move(unit: Unit, _old_hex: Hex, _new_hex: Hex) -> void:
	var attackable_units = get_units_in_range(unit)
	
	if attackable_units.is_empty():
		return
	
	if unit.type == Unit.UNIT_TYPE.PLAYER:
		# Set up for player attack selection
		_current_attackable_units = attackable_units
		_waiting_for_attack = true
		print("Player can attack: ", attackable_units)
		# Highlight attackable units here
		for target in attackable_units:
			target.current_hex.highlight("g")  # Highlight in red for attackable
	else:
		# Enemies automatically attack if they can
		resolve_combat(unit, attackable_units[0])

func resolve_combat(attacker: Unit, defender: Unit) -> void:
	game_state = GameState.COMBAT
	
	print("%s attacks %s!" % [attacker.name, defender.name])
	SignalBus.combat_started.emit(attacker, defender)
	
	defender.take_damage(1)  # Basic damage
	print(defender.current_health)
	if defender.current_health <= 0:
		# First remove from grid management
		HexGridManager.unregister_unit(defender)
		
		# Remove from unit management
		UnitManager.remove_unit(defender)
		
		# Free the unit instance
		defender.queue_free()
		
		SignalBus.unit_died.emit(defender)
	
	SignalBus.combat_ended.emit()

# Turn Management
func _on_player_turn(_player: Player):
	var attackable = get_units_in_range(player)
	if not attackable.is_empty():
		print("Player can attack units: ", attackable)
		# Maybe highlight attackable units

func _on_player_turn_end(_player: Player):
	player.clear_highlights()
	_waiting_for_attack = false
	_current_attackable_units.clear()
	
	# Clear attack highlights
	for unit in UnitManager.get_all_units():
		if unit != player:
			unit.current_hex.unhighlight()

func _on_enemy_turn(unit: Unit):
	var attackable = get_units_in_range(unit)
	if not attackable.is_empty():
		print("Enemy can attack units: ", attackable)

func _on_enemy_turn_end(unit: Unit):
	unit.clear_highlights()
	_units_in_combat_range.clear()

func _on_all_turns_end(units):
	for unit in units:
		if unit.type == Unit.UNIT_TYPE.PLAYER:
			player.show_movement_range(player)
		else:
			unit.show_movement_range(unit)

func _on_hex_selected(hex: Hex) -> void:
	if game_state != GameState.PLAYING:
		return
		
	var current_unit = HexGridManager.get_current_unit()
	if current_unit == null:
		return
	
	# If we're waiting for an attack target
	if _waiting_for_attack:
		if HexGridManager.has_units(hex):
			var target_unit = HexGridManager._hex_units[hex][0]
			if target_unit in _current_attackable_units:
				resolve_combat(current_unit, target_unit)
				_waiting_for_attack = false
				_current_attackable_units.clear()
		return
	
	# Otherwise, handle movement
	var old_hex = current_unit.current_hex
	HexGridManager.move_unit(current_unit, hex)
	check_combat_after_move(current_unit, old_hex, hex)

func _on_unit_died(unit: Unit) -> void:
	print(unit, ": destroyed")
	UnitManager.remove_unit(unit)
	check_game_over()

func _on_combat_started(_attacker: Unit, _defender: Unit) -> void:
	game_state = GameState.COMBAT

func _on_combat_ended() -> void:
	game_state = GameState.PLAYING

func check_game_over() -> void:
	if player.current_health <= 0:
		end_game(false)
		return
	
	var enemies = UnitManager.get_enemies()
	if enemies.is_empty():
		end_game(true)
		return

func end_game(player_won: bool) -> void:
	game_state = GameState.GAME_OVER
	SignalBus.game_over.emit(player_won)
