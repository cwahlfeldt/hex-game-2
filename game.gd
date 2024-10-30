extends Node3D

var player: Player
var rng = RandomNumberGenerator.new()
var is_moving = false

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
	
	var hex_grid = HexGridManager.get_grid()
	var traversable_hex_grid = HexGridManager.get_traversable_grid()
	var player_start_hex = hex_grid[HexGridManager.player_start_index]
	
	player = UnitManager.spawn_player(player_start_hex)
	TurnQueue.add_entity(player)
	SignalBus.players_turn.emit(TurnQueue.get_current(), true)
	
	range(1).map(func(_n):
		var random_hex = traversable_hex_grid[rng.randi_range(HexGridManager.map_size * 7, traversable_hex_grid.size())]
		var enemy = UnitManager.spawn_enemy(random_hex)
		TurnQueue.add_entity(enemy)
	)

	# SignalBus.turn_end.emit(TurnQueue.get_current())

	# update_grid(TurnQueue.get_current())
	
	# print(TurnQueue.get_current().name)
	print("It's now " + TurnQueue.get_current().name + "'s turn!  ", TurnQueue.get_index())

func update_grid(unit_to_exclude: Unit):
	unit_to_exclude.current_hex.traversable = true
	var units = TurnQueue.get_all_entities().filter(func(unit):
		return unit.name != unit_to_exclude.name
	)

	print(units)

	for unit in units:
		unit.current_hex.traversable = false

	HexGridManager.update_pathfinding()
# 	# for unit in units

func _on_player_start(to_hex):
	var unit: Unit = TurnQueue.get_current()
	if unit and unit.name == 'Player':
		unit.move_unit(to_hex)
		SignalBus.players_turn.emit(unit)

func _on_turn_changed(unit: Unit):
	print("It's now " + unit.name + "'s turn!  ", TurnQueue.get)
	if unit and unit.name != 'Player':
		unit.move_unit(player.current_hex)
		SignalBus.enemy_turn.emit(unit)
	else:
		SignalBus.players_turn_end.emit(unit)

func _on_turn_end(unit: Unit):

	if unit and unit.name != 'Player':
		SignalBus.enemy_turn_end.emit(unit)
	update_grid(unit)
	TurnQueue.next_turn()
