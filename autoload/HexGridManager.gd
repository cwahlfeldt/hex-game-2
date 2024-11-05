extends HexGrid

signal grid_initialized

# Grid Configuration
@export var holes_to_remove: int = 8

@export_group("Debug Visualization")
@export var show_labels: bool = true
@export var show_astar: bool = false

# Debug visualizer for AStar pathfinding
var _astar_debug: AStarDebugVisualizer

# Unit Management Dictionaries
var _unit_positions: Dictionary = {} # Unit -> Hex mapping
var _hex_units: Dictionary = {} # Hex -> Array[Unit] mapping
var _player_unit: Unit = null

var player_start_index: int:
	get: return map_size + 2

func _ready() -> void:
	SignalBus.turn_end.connect(_on_turn_end)
	SignalBus.selected_hex.connect(_on_selected_hex)
	# SignalBus.player_turn_end.connect(_on_player_turn_end)

	_setup_grid_container()

# Grid Setup Methods
func initialize_grid(config: Dictionary = {}) -> void:
	_apply_configuration(config)
	initialize()
	_remove_random_hexes()
	_setup_debug_visualization()
	_setup_pathfinding()

	if show_labels:
		_create_debug_labels()
	
	grid_initialized.emit()

func _apply_configuration(config: Dictionary) -> void:
	if config.has("map_size"):
		map_size = config.map_size
	if config.has("hex_size"):
		hex_size = config.hex_size
	if config.has("holes_to_remove"):
		holes_to_remove = config.holes_to_remove
	if config.has("show_labels"):
		show_labels = config.show_labels
	if config.has("show_astar"):
		show_astar = config.show_astar

func _setup_debug_visualization() -> void:
	if show_astar:
		var astar_debug_scene = load("res://scenes/Debug/AStarDebugVisualizer.tscn")
		_astar_debug = astar_debug_scene.instantiate()
		_grid_container.add_child(_astar_debug)
		_astar_debug.visualize_astar(_astar)

func _remove_random_hexes() -> void:
	if (_grid.size() > 2):
		for i in range(holes_to_remove):
			var random_index = (randi() % (_grid.size() - 1)) + 1
			var hex_to_remove = _grid[random_index]
			
			if hex_to_remove.index == player_start_index:
				continue
			
			_disable_hex(hex_to_remove)

func _disable_hex(hex: Hex) -> void:
	for neighbor in hex.neighbors:
		neighbor.neighbors.erase(hex)
	
	hex.neighbors.clear()
	hex.traversable = false
	
	if _astar and _astar.has_point(hex.index):
		_astar.remove_point(hex.index)

func _create_debug_labels() -> void:
	for hex in _grid:
		if hex.traversable:
			var label_position = Vector3(hex.get_location().x, 0.3, hex.get_location().z)
			var label = Utilities.create_label(
				str(hex.index),
				label_position,
				Color.BLACK
			)
			
			label.rotate(Vector3(1, 0, 0), 30)
			_grid_container.add_child(label)

# Unit Management Methods
func register_unit(unit: Unit, hex: Hex) -> void:
	if not _unit_positions.has(unit):
		_unit_positions[unit] = hex
		if not _hex_units.has(hex):
			_hex_units[hex] = []
		_hex_units[hex].append(unit)
		unit.current_hex = hex
		unit.global_position = hex.location
		
		if unit.type == Unit.UNIT_TYPE.PLAYER:
			_player_unit = unit
		
		TurnQueue.add_entity(unit)

func unregister_unit(unit: Unit) -> void:
	if _unit_positions.has(unit):
		var current_hex = _unit_positions[unit]
		_hex_units[current_hex].erase(unit)
		if _hex_units[current_hex].is_empty():
			_hex_units.erase(current_hex)
		_unit_positions.erase(unit)

		TurnQueue.remove_entity(unit)

func has_units(hex: Hex) -> bool:
	return _hex_units.has(hex) and not _hex_units[hex].is_empty()

func get_available_moves(from_hex: Hex, move_range: int) -> Array[Hex]:
	var available: Array[Hex] = []
	for hex in _grid:
		if not hex.traversable or has_units(hex) or hex == from_hex:
			continue
		
		var path = find_path(from_hex.index, hex.index)
		if path.size() > 1 and path.size() - 1 <= move_range:
			available.append(hex)
	
	return available

func move_unit(unit: Unit, to_hex: Hex) -> void:
	var from_hex = unit.current_hex
	
	if from_hex == to_hex:
		return
	
	var available_moves = get_available_moves(from_hex, unit.move_range)
	if available_moves.is_empty():
		SignalBus.turn_end.emit(unit)
		return
	
	var path = find_path(from_hex.index, to_hex.index)
	var target_hex: Hex
	
	if path.size() > 1 and path.size() - 1 <= unit.move_range and not has_units(path[-1]):
		target_hex = path[-1]
	else:
		var closest_hex = available_moves[0]
		var closest_distance = get_hex_distance(closest_hex, to_hex)
		
		for hex in available_moves:
			var distance = get_hex_distance(hex, to_hex)
			if distance < closest_distance:
				closest_hex = hex
				closest_distance = distance
		
		target_hex = closest_hex
		path = find_path(from_hex.index, target_hex.index)
	
	_update_unit_position(unit, from_hex, target_hex)
	
	var locations: Array[Vector3] = []
	for hex in path:
		locations.append(hex.location)
	
	AnimationManager.through_with_callback_and_rotate(
		unit,
		locations,
		func():
			SignalBus.turn_end.emit(unit)
	)

func _update_unit_position(unit: Unit, from_hex: Hex, target_hex: Hex) -> void:
	if from_hex and _hex_units.has(from_hex):
		_hex_units[from_hex].erase(unit)
		if _hex_units[from_hex].is_empty():
			_hex_units.erase(from_hex)
	
	_unit_positions[unit] = target_hex
	unit.current_hex = target_hex
	
	if not _hex_units.has(target_hex):
		_hex_units[target_hex] = []
	_hex_units[target_hex].append(unit)

func get_hex_units():
	return _hex_units

func get_units_in_attack_range(from_unit: Unit, attack_range: int) -> Array[Unit]:
	var units_in_range: Array[Unit] = []
	var from_hex = from_unit.current_hex
	
	# Loop through our existing hex_units dictionary
	for hex in _hex_units:
		# Simple hex distance check
		if get_hex_distance(from_hex, hex) <= attack_range:
			# Add all units on this hex except the attacking unit
			for unit in _hex_units[hex]:
				if unit != from_unit:
					units_in_range.append(unit)
	
	return units_in_range

func get_enemies():
	return TurnQueue.get_all_entities().filter(func(unit): return unit.type != Unit.UNIT_TYPE.PLAYER)

# Turn Management
func get_current_unit() -> Unit:
	return TurnQueue.get_current()

func is_unit_turn(unit: Unit) -> bool:
	return TurnQueue.get_current() == unit

func _on_turn_end(last_unit: Unit) -> void:
	if not is_unit_turn(last_unit):
		return

	TurnQueue.next_turn()
	var current_unit = TurnQueue.get_current()
	
	# Handle signals based on unit types
	if last_unit.type == Unit.UNIT_TYPE.PLAYER:
		SignalBus.player_turn_end.emit(last_unit)
		# Start enemy sequence after player
		if current_unit.type != Unit.UNIT_TYPE.PLAYER:
			SignalBus.enemy_turn.emit(current_unit)
	else:
		SignalBus.enemy_turn_end.emit(last_unit)
		# Only chain to next enemy if there is one
		if current_unit and current_unit.type != Unit.UNIT_TYPE.PLAYER:
			SignalBus.enemy_turn.emit(current_unit)
	
	SignalBus.unit_turn_end.emit(current_unit)

# Triggers the players turn
func _on_selected_hex(hex: Hex):
	var unit = TurnQueue.get_current()
	if unit.type == Unit.UNIT_TYPE.PLAYER:
		SignalBus.player_turn.emit(unit, hex)
