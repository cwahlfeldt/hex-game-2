extends Node3D

var player: Player
var rng = RandomNumberGenerator.new()
var is_moving = false

func _ready() -> void:
	SignalBus.selected_hex.connect(_on_selected_hex)
	SignalBus.turn_change.connect(_on_turn_changed)
	SignalBus.turn_end.connect(_on_unit_move_end)
	
	HexGridManager.configure({
		"map_size": 5,
		"show_labels": true,
		"holes_to_remove": 8
	})
	
	var hex_grid = HexGridManager.get_grid()
	
	player = UnitManager.spawn_player(hex_grid[0])
	TurnQueue.add_entity(player)
	
	range(2).map(func(n):
		var random_hex = hex_grid[rng.randi_range(30, hex_grid.size())]
		var enemy = UnitManager.spawn_enemy(random_hex)
		TurnQueue.add_entity(enemy)
	)
	
	print("It's now " + TurnQueue.get_current().name + "'s turn!  ", TurnQueue.get_current().current_hex)

func _on_selected_hex(to_hex):
	var unit: Unit = TurnQueue.get_current()
	if unit and unit.name == 'Player' and not is_moving:
		unit.move_unit(to_hex)

func _on_turn_changed(unit: Unit):
	print("It's now " + unit.name + "'s turn!  ", unit.current_hex)
	if unit and unit.name != 'Player':
		unit.move_unit(player.current_hex)
	else:
		is_moving = false

func _on_unit_move_end(_unit):
	TurnQueue.next_turn()
