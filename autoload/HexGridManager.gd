extends HexGrid

static var instance: HexGridManager

signal grid_initialized

@export var holes_to_remove: int = 8

@export_group("Debug Visualization")
@export var show_labels: bool = true
@export var show_astar: bool = true

var _astar_debug: AStarDebugVisualizer

# Unit management
var _unit_positions: Dictionary = {} # Unit -> Hex mapping
var _hex_units: Dictionary = {} # Hex -> Array[Unit] mapping
var _player_unit: Unit = null

var player_start_index: int:
	get: return map_size + 2

func _init() -> void:
	instance = self

func _ready() -> void:
	SignalBus.turn_end.connect(_on_turn_end)
	_setup_grid_container()

func initialize_grid(config: Dictionary = {}) -> void:
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
	
	initialize()
	_remove_random_hexes()
	_setup_debug_visualization()
	_setup_pathfinding()


	if show_labels:
		_create_debug_labels()
	
	grid_initialized.emit()
	
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
			
			# Remove this hex from its neighbors' lists
			for neighbor in hex_to_remove.neighbors:
				neighbor.neighbors.erase(hex_to_remove)
			
			# Clear this hex's neighbors
			hex_to_remove.neighbors.clear()
			hex_to_remove.traversable = false
			
			# Update pathfinding
			if _astar and _astar.has_point(hex_to_remove.index):
				_astar.remove_point(hex_to_remove.index)

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

# Unit Management
func register_unit(unit: Unit, hex: Hex) -> void:
	if not _unit_positions.has(unit):
		#print("Registering unit: ", unit.name, " to hex: ", hex.index)  # Debug
		_unit_positions[unit] = hex
		if not _hex_units.has(hex):
			_hex_units[hex] = []
		_hex_units[hex].append(unit)
		unit.current_hex = hex # Make sure this is set
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

# Turn Management
func get_current_unit() -> Unit:
	return TurnQueue.get_current()

func is_unit_turn(unit: Unit) -> bool:
	return TurnQueue.get_current() == unit

func can_move_to(hex: Hex) -> bool:
	return hex.traversable and not has_units(hex)

func move_unit(unit: Unit, to_hex: Hex) -> void:
	var from_hex = unit.current_hex
	var target_hex = to_hex
	
	# If target or path has units, find alternate path
	if has_units(to_hex):
		print("Target hex occupied, finding alternate path")
		# Check surrounding hexes of target, starting with closest
		var valid_neighbors = []
		for neighbor in to_hex.neighbors:
			if can_move_to(neighbor):
				var test_path = find_path(from_hex.index, neighbor.index)
				# Check if path is clear
				var path_clear = true
				for hex in test_path:
					if has_units(hex) and hex != from_hex:
						path_clear = false
						break
				if path_clear:
					valid_neighbors.append(neighbor)
		
		if valid_neighbors.size() > 0:
			target_hex = valid_neighbors[0]
		else:
			print("No valid path found")
			SignalBus.turn_end.emit(unit)
			return
	
	var path = find_path(from_hex.index, target_hex.index)
	
	# Check if any hex in path has units
	var valid_path = []
	for hex in path:
		if has_units(hex) and hex != from_hex:
			break
		valid_path.append(hex)
	
	if valid_path.size() <= 1:
		print("No valid path without unit collision")
		SignalBus.turn_end.emit(unit)
		return
		
	# Limit path to move range
	if valid_path.size() > unit.move_range + 1:
		valid_path = valid_path.slice(0, unit.move_range + 1)
	
	target_hex = valid_path[valid_path.size() - 1]
	
	# Update hex tracking
	if from_hex:
		if _hex_units.has(from_hex):
			_hex_units[from_hex].erase(unit)
			if _hex_units[from_hex].is_empty():
				_hex_units.erase(from_hex)
	
	# Update unit position
	_unit_positions[unit] = target_hex
	unit.current_hex = target_hex

	if unit.type == Unit.UNIT_TYPE.PLAYER:
		SignalBus.players_turn.emit(unit)
	else:
		SignalBus.enemy_turn.emit(unit)
	
	# Add to new hex
	if not _hex_units.has(target_hex):
		_hex_units[target_hex] = []
	_hex_units[target_hex].append(unit)
	
	# Move animation
	AnimationManager.through_with_callback_and_rotate(
		unit,
		[from_hex.location, target_hex.location],
		func():
			SignalBus.turn_end.emit(unit)
	)

# In HexGridManager.gd
func _on_turn_end(unit: Unit) -> void:
	if is_unit_turn(unit):
		if (unit.type == Unit.UNIT_TYPE.PLAYER):
			_player_unit.current_hex = unit.current_hex
			SignalBus.players_turn_end.emit(unit, true)
		
		TurnQueue.next_turn()

		var current_unit = TurnQueue.get_current()
		if (current_unit.type != Unit.UNIT_TYPE.PLAYER):
			SignalBus.enemy_turn_end.emit(current_unit, true)
			move_unit(current_unit, _player_unit.current_hex)

# Utility
func get_instance() -> HexGridManager:
	return instance
