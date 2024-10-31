extends Node3D

var player: Player
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	SignalBus.selected_hex.connect(_on_player_start)
	SignalBus.turn_change.connect(_on_turn_changed)
	SignalBus.turn_end.connect(_on_turn_end)
	
	HexGridManager.configure({
		"map_size": 5,
		"show_labels": false,
		"show_astar": true,
		"holes_to_remove": 8
	})
	
	setup_game()
	await update_blocked_hexes()

func setup_game() -> void:
	var hex_grid = HexGridManager.get_grid()
	var traversable_hex_grid = HexGridManager.get_traversable_grid()
	var player_start_hex = hex_grid[HexGridManager.player_start_index]
	
	player = UnitManager.spawn_player(player_start_hex)
	TurnQueue.add_entity(player)
	
	for _i in range(2):
		var random_hex = traversable_hex_grid[rng.randi_range(HexGridManager.map_size * 7, traversable_hex_grid.size())]
		var enemy = UnitManager.spawn_enemy(random_hex)
		TurnQueue.add_entity(enemy)
	
	SignalBus.players_turn.emit(TurnQueue.get_current(), true)

func update_blocked_hexes() -> void:
	# Block all unit hexes first
	for unit in TurnQueue.get_all_entities():
		unit.current_hex.traversable = false
	
	# Unblock current unit's hex
	TurnQueue.get_current().current_hex.traversable = true
	HexGridManager.update_pathfinding()
	await get_tree().create_timer(1).timeout

func _on_player_start(to_hex) -> void:
	var unit = TurnQueue.get_current()
	if unit and unit.name == 'Player':
		unit.move_unit(to_hex)
		SignalBus.players_turn.emit(unit)

func _on_turn_changed(unit: Unit) -> void:
	update_blocked_hexes()
	
	if unit and unit.name != 'Player':
		unit.move_unit(player.current_hex)
		SignalBus.enemy_turn.emit(unit)
	else:
		SignalBus.players_turn_end.emit(unit)

func _on_turn_end(unit: Unit) -> void:
	TurnQueue.next_turn()
	if unit and unit.name != 'Player':
		SignalBus.enemy_turn_end.emit(unit)
	await update_blocked_hexes()
