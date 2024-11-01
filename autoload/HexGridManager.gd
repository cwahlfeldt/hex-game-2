extends HexGrid

static var instance: HexGridManager

signal unit_moved(from_hex: Hex, to_hex: Hex, unit: Node3D)
signal grid_initialized

@export var holes_to_remove: int = 8

@export_group("Debug Visualization")
@export var show_labels: bool = true
@export var show_astar: bool = false

var _astar_debug: AStarDebugVisualizer

# Unit management
var _unit_positions: Dictionary = {}  # Unit -> Hex mapping
var _hex_units: Dictionary = {}       # Hex -> Array[Unit] mapping
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
			
			hex_to_remove.traversable = false
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
		print("Registering unit: ", unit.name, " to hex: ", hex.index)  # Debug
		_unit_positions[unit] = hex
		if not _hex_units.has(hex):
			_hex_units[hex] = []
		_hex_units[hex].append(unit)
		unit.current_hex = hex  # Make sure this is set
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

# Turn Management
func get_current_unit() -> Unit:
	return TurnQueue.get_current()

func is_unit_turn(unit: Unit) -> bool:
	return TurnQueue.get_current() == unit

func can_move_to(hex: Hex) -> bool:
	return hex.traversable and not _hex_units.has(hex)

# Modify move_unit to ensure turn_end is called even if movement fails
func move_unit(unit: Unit, to_hex: Hex) -> void:
	if not is_unit_turn(unit):
		print("Not unit's turn")
		return
		
	var from_hex = _unit_positions[unit]
	if from_hex == null:
		print("No starting hex")
		SignalBus.turn_end.emit(unit)
		return
		
	var path = find_path(from_hex.index, to_hex.index)
	if path.size() > 1:
		var limited_path = path.slice(0, unit.move_range + 1)
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
		
		# Move animation
		var locations: Array[Vector3] = []
		for hex in limited_path:
			locations.append(hex.location)
		
		AnimationManager.through_with_callback_and_rotate(
			unit,
			locations,
			func(): SignalBus.turn_end.emit(unit)
		)
		
		unit_moved.emit(from_hex, target_hex, unit)
	else:
		# No valid path found, end turn
		print("No valid path found")
		SignalBus.turn_end.emit(unit)

# In HexGridManager.gd
func _on_turn_end(unit: Unit) -> void:
	print("Turn ending for: ", unit.name, ' ', unit.current_hex.index)
		  # Debug
	if (unit.type == Unit.UNIT_TYPE.PLAYER):
		_player_unit.current_hex = unit.current_hex
	if is_unit_turn(unit):
		#update_traversable_hexes()

		TurnQueue.next_turn()
		var current_unit = TurnQueue.get_current()
		#print("New turn starting for: ", current_unit.name)  # Debug
		
		if current_unit.type == Unit.UNIT_TYPE.GRUNT:
			#await get_tree().create_timer(0.5).timeout
			var path = find_path(current_unit.current_hex.index, _player_unit.current_hex.index)
			#print("Path found for ", current_unit.name, ": ", path.size(), " hexes")  # Debug
			if path.size() > 1:
				move_unit(current_unit, path[1])
			else:
				#print("No path found, ending turn")  # Debug
				SignalBus.turn_end.emit(current_unit)
		else:
			#print("Player's turn")  # Debug
			SignalBus.players_turn.emit(current_unit, true)
	
#func update_traversable_hexes() -> void:
	#print("Updating traversable hexes")  # Debug print
	#_setup_pathfinding()
	#
	## Make hexes with units non-traversable
	#for unit in _unit_positions:
		#var hex = _unit_positions[unit]
		#print("Making hex ", hex.index, " non-traversable for unit ", unit.name)  # Debug print
		#if _astar and _astar.has_point(hex.index):
			#_astar.remove_point(hex.index)
			#
			## Optionally disconnect from neighbors
			#for neighbor in hex.neighbors:
				#if _astar.has_point(neighbor.index):
					#if _astar.are_points_connected(hex.index, neighbor.index):
						#_astar.disconnect_points(hex.index, neighbor.index)
	#
	# Update visualization
	if show_astar and _astar_debug:
		_astar_debug.visualize_astar(_astar)

# Utility
static func get_instance() -> HexGridManager:
	return instance
