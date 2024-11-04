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

func initialize_game(config) -> void:
	# Initialize hex grid
	HexGridManager.initialize_grid({
		"map_size": grid_size,
		"holes_to_remove": holes_to_remove,
		"show_labels": true
	})
	
	# Spawn units
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
	# Get valid spawn positions
	var grid = HexGridManager.get_grid()
	var traversable_grid = HexGridManager.get_traversable_grid()
	
	# Spawn player
	player = UnitManager.spawn_player(
		grid[HexGridManager.player_start_index]
	)
	
	# Spawn enemies
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

## Logic for player starts here
func _on_player_turn(_player: Player):
	get_units_in_range(player)
	pass

## Logic for enemy starts here
func _on_enemy_turn(unit):
	pass

func _on_player_turn_end(player: Player):
	player.clear_highlights()
	get_units_in_range(player)


func _on_enemy_turn_end(unit):
	unit.clear_highlights()

func get_units_in_range(unit):
	for u in UnitManager.get_all_units():
		if u != unit:
			var path_to_unit = HexGridManager.find_path(unit.current_hex.index, u.current_hex.index)
			var true_path_to_unit = path_to_unit.slice(1, -1)
			print("\n", unit.name, " to ", u.name, " | ", true_path_to_unit.size())
			if unit.type == Unit.UNIT_TYPE.PLAYER and true_path_to_unit.size() == 1:
				print(unit.name, " can attack")
				
			if u.type == Unit.UNIT_TYPE.GRUNT and true_path_to_unit.size() == 2:
				print(u.name, " can attack")

				
func _on_all_turns_end(units):
	print("all turns have ended")
	for unit in units:
		if unit.type == Unit.UNIT_TYPE.PLAYER:
			player.show_movement_range(player)
		else:
			unit.show_movement_range(unit)

# Signal Handlers
func _on_hex_selected(hex: Hex) -> void:
	if game_state != GameState.PLAYING:
		return
		
	var current_unit = HexGridManager.get_current_unit()
	if current_unit != null:
		HexGridManager.move_unit(current_unit, hex)

#func _on_unit_died(unit: Unit) -> void:
	#check_game_over()
#
#func _on_combat_started(attacker: Unit, defender: Unit) -> void:
	#game_state = GameState.COMBAT
	#resolve_combat(attacker, defender)
#
#func _on_combat_ended() -> void:
	#game_state = GameState.PLAYING

# Game Logic
func resolve_combat(attacker: Unit, defender: Unit) -> void:
	# Combat resolution logic here
	var damage = calculate_damage(attacker, defender)
	defender.take_damage(damage)
	
	if defender.current_health <= 0:
		SignalBus.unit_died.emit(defender)
	
	SignalBus.combat_ended.emit()

func calculate_damage(attacker: Unit, defender: Unit) -> int:
	# Damage calculation logic
	return 1

func check_game_over() -> void:
	var player = UnitManager.get_player()
	if player.current_health <= 0:
		end_game(false)  # Player lost
		return
	
	var enemies = UnitManager.get_enemies()
	if enemies.is_empty():
		end_game(true)  # Player won
		return

func end_game(player_won: bool) -> void:
	game_state = GameState.GAME_OVER
	SignalBus.game_over.emit(player_won)
