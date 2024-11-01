extends HexGrid

# Make key functionality accessible globally via GameManager.grid
static var instance: HexGridManager

signal unit_moved(from_hex: Hex, to_hex: Hex, unit: Node3D)
signal grid_initialized

@export_group("Game Configuration")
@export var holes_to_remove: int = 8

@export_group("Debug Visualization")
@export var show_labels: bool = true
@export var show_astar: bool = true

# Unit management
var _unit_positions: Dictionary = {}  # Unit -> Hex mapping
var _hex_units: Dictionary = {}       # Hex -> Array[Unit] mapping

var player_start_index: int:
	get: return map_size + 2

var _astar_debug: AStarDebugVisualizer
var _checked_hexes: Dictionary
var _valid_moves: Array[Hex]
var _current_movement_range: int
var _is_initialized: bool = false

func _init() -> void:
	instance = self

func _ready() -> void:
	# Don't automatically initialize in _ready
	# Wait for explicit initialization call
	SignalBus.update_hex_grid.connect(_on_update_grid)
	SignalBus.turn_end.connect(_on_turn_end)
	_setup_grid_container()

# Core Initialization
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
	
	_is_initialized = true
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
			
			print("Making hex %d non-traversable" % hex_to_remove.index)
			hex_to_remove.traversable = false

func _create_debug_labels() -> void:
	print("Creating debug labels...")
	for hex in _grid:
		print("Checking hex %d - traversable: %s" % [hex.index, hex.traversable])
		if hex.traversable:
			print("Creating labels for hex %d" % hex.index)
			var label_position = Vector3(hex.get_location().x, 0.3, hex.get_location().z)
			
			var labels = {
				"index": {"text": hex.index, "offset": Vector3(0, -0.06, 0), "color": Color.BLACK, "size": 90},
				"q": {"text": hex.coord.q, "offset": Vector3(0, 0.45, 0), "color": Color.BLACK, "size": 70},
				"r": {"text": hex.coord.r, "offset": Vector3(-0.4, -0.45, 0), "color": Color.BLACK, "size": 70},
				"s": {"text": hex.coord.s, "offset": Vector3(0.4, -0.45, 0), "color": Color.BLACK, "size": 70}
			}
			
			for label_data in labels.values():
				var label = Utilities.create_label(
					label_data.text, 
					label_position,
					label_data.color
				)
				label.font_size = label_data.size
				label.rotate(Vector3(1, 0, 0), 30)
				label.translate(label_data.offset)
				_grid_container.add_child(label)

# Unit Management
func register_unit(unit: Unit, hex: Hex) -> void:
	if not _unit_positions.has(unit):
		_unit_positions[unit] = hex
		if not _hex_units.has(hex):
			_hex_units[hex] = []
		_hex_units[hex].append(unit)
		unit.current_hex = hex
		unit.global_position = hex.location
		
		# Add to autoloaded turn queue
		TurnQueue.add_entity(unit)

func unregister_unit(unit: Unit) -> void:
	if _unit_positions.has(unit):
		var current_hex = _unit_positions[unit]
		_hex_units[current_hex].erase(unit)
		if _hex_units[current_hex].is_empty():
			_hex_units.erase(current_hex)
		_unit_positions.erase(unit)
		
		# Remove from autoloaded turn queue
		TurnQueue.remove_entity(unit)

func move_unit(unit: Unit, to_hex: Hex) -> void:
	# Optional: Add turn order validation
	if not is_unit_turn(unit):
		push_warning("Attempting to move unit out of turn")
		return
		
	var from_hex = _unit_positions[unit]
	if from_hex == null:
		push_warning("Attempting to move unregistered unit")
		return
		
	var path = find_path(from_hex.index, to_hex.index)
	if path.size() > 1:
		var limited_path = path.slice(0, unit.move_range + 1)  # account for current hex
		var target_hex = limited_path[limited_path.size() - 1]
		
		# Update position tracking
		_hex_units[from_hex].erase(unit)
		if _hex_units[from_hex].is_empty():
			_hex_units.erase(from_hex)
			
		if not _hex_units.has(target_hex):
			_hex_units[target_hex] = []
		_hex_units[target_hex].append(unit)
		_unit_positions[unit] = target_hex
		unit.current_hex = target_hex
		
		# Handle movement animation
		var locations: Array[Vector3] = []
		locations.assign(limited_path.map(func(hex) -> Vector3: return hex.location))
		AnimationManager.through_with_callback_and_rotate(
			unit,
			locations,
			func(): SignalBus.turn_end.emit(unit)
		)
		
		unit_moved.emit(from_hex, target_hex, unit)

# Turn Management Methods
func get_current_unit() -> Unit:
	return TurnQueue.get_current()

func get_next_unit() -> Unit:
	return TurnQueue.get_next()

func is_unit_turn(unit: Unit) -> bool:
	return TurnQueue.get_current() == unit

# Movement and Position Queries
func get_unit_hex(unit: Unit) -> Hex:
	return _unit_positions.get(unit)

func get_hex_units(hex: Hex) -> Array[Unit]:
	return _hex_units.get(hex, []) if hex != null else []

func has_units(hex: Hex) -> bool:
	return _hex_units.has(hex) and not _hex_units[hex].is_empty()

func can_move_to(hex: Hex) -> bool:
	return hex.traversable and not has_units(hex)

func get_units_by_type(type: Unit.UNIT_TYPE) -> Array[Unit]:
	return _unit_positions.keys().filter(
		func(unit): return unit.type == type
	)

func get_valid_moves(from_hex: Hex, movement_range: int) -> Array[Hex]:
	_checked_hexes.clear()
	_valid_moves.clear()
	_current_movement_range = movement_range
	
	_check_hex_recursive(from_hex, 0)
	
	return _valid_moves

func _check_hex_recursive(hex: Hex, steps: int) -> void:
	if steps > _current_movement_range:
		return
		
	if can_move_to(hex):
		_valid_moves.append(hex)
		
	_checked_hexes[hex] = steps
	
	for neighbor in hex.neighbors:
		if neighbor in _checked_hexes and _checked_hexes[neighbor] <= steps + 1:
			continue
		_check_hex_recursive(neighbor, steps + 1)

# Range Queries
func get_units_in_range(from_hex: Hex, range: int) -> Array[Unit]:
	var units: Array[Unit] = []
	var hexes = get_hexes_in_range(from_hex, range)
	for hex in hexes:
		units.append_array(get_hex_units(hex))
	return units

func get_hexes_in_range(from_hex: Hex, range: int) -> Array[Hex]:
	var hexes: Array[Hex] = []
	var checked: Dictionary = {}
	_get_hexes_in_range_recursive(from_hex, range, 0, checked, hexes)
	return hexes

func _get_hexes_in_range_recursive(hex: Hex, max_range: int, current_range: int, 
	checked: Dictionary, result: Array[Hex]) -> void:
	if current_range > max_range:
		return
		
	if not checked.has(hex):
		checked[hex] = current_range
		result.append(hex)
		
		for neighbor in hex.neighbors:
			if not checked.has(neighbor) or checked[neighbor] > current_range + 1:
				_get_hexes_in_range_recursive(neighbor, max_range, 
					current_range + 1, checked, result)

# Signal Handlers
func _on_turn_end(unit: Unit) -> void:
	if is_unit_turn(unit):
		TurnQueue.next_turn()

func _on_update_grid() -> void:
	print('updated')
	_setup_pathfinding()
	if show_astar:
		_astar_debug.visualize_astar(_astar)

# Utility Methods
func get_instance() -> HexGridManager:
	return instance

func is_initialized() -> bool:
	return instance != null and instance._is_initialized
