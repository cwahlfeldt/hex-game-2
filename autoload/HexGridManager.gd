extends Node3D

const hex_scene = preload("res://scenes/Hex/Hex.tscn")

const directions = {
	"northWest": {"q": -1, "r": 0, "s": 1},
	"north": {"q": 0, "r": -1, "s": 1},
	"northEast": {"q": 1, "r": -1, "s": 0},
	"southWest": {"q": -1, "r": 1, "s": 0},
	"south": {"q": 0, "r": 1, "s": -1},
	"southEast": {"q": 1, "r": 0, "s": -1}
}

# Configuration variables with default values
var map_size: int = 5
var player_start_index: int = map_size + 2
var hex_size: float = 1.1
var show_labels: bool = true
var show_astar: bool = false
var holes_to_remove: int = 8

# Internal variablesd
var _grid: Array[Hex] = []
var _astar: AStar3D
var _initialized: bool = false
var _grid_container: Node3D
var _astar_debug: AStarDebugVisualizer

func _ready() -> void:
	SignalBus.update_hex_grid.connect(_on_update_grid)
	# Only create the container node, but don't initialize the grid yet
	_grid_container = Node3D.new()
	_grid_container.name = "HexGridContainer"



	add_child(_grid_container)
	if show_astar:
		var astar_debug_scene = load("res://scenes/Debug/AStarDebugVisualizer.tscn")
		_astar_debug = astar_debug_scene.instantiate()
		_grid_container.add_child(_astar_debug)

func configure(config: Dictionary = {}) -> void:
	if config.has("map_size"):
		map_size = config.map_size
		player_start_index = config.map_size + 2
	if config.has("hex_size"):
		hex_size = config.hex_size
	if config.has("show_labels"):
		show_labels = config.show_labels
	if config.has("show_astar"):
		show_astar = config.show_astar
	if config.has("holes_to_remove"):
		holes_to_remove = config.holes_to_remove
	
	# Initialize or reinitialize after configuration
	if _initialized:
		clear()
	initialize()

func clear() -> void:
	for hex in _grid:
		hex.queue_free()
	
	for child in _grid_container.get_children():
		if child is Label3D:
			child.queue_free()
	
	_grid.clear()
	_astar = null
	_initialized = false

func initialize() -> void:
	clear()
	_generate_grid()
	_generate_neighbors()
	_setup_pathfinding()
	_initialized = true

func _generate_grid() -> void:
	var hex_coords = _generate_hex_coords()
	hex_coords.sort_custom(func(a, b):
		if a.r != b.r:
			return a.r > b.r
		return a.q > b.q
	)
	
	# Create hex instances
	for i in hex_coords.size():
		var coord = hex_coords[i]
		var location = _hex_to_3d(coord.q, coord.r)
		
		var hex_data = {
			"index": i,
			"coord": coord,
			"location": location,
			"neighbors": []
		}
		
		var hex_instance: Hex = hex_scene.instantiate() as Hex
		hex_instance.name = "Hex_" + str(i)
		hex_instance.set_data(hex_data)
		_grid.append(hex_instance)
	
	_remove_random_hexes()
	_create_visual_elements()

func _generate_neighbors():
	for i in _grid.size():
		var hex = _grid[i]
		var neighbors: Array = []
		for direction in directions.values():
			var neighbor_coord = {
				"q": hex.coord.q + direction.q,
				"r": hex.coord.r + direction.r,
				"s": hex.coord.s + direction.s
			}
			
			var neighbor = _find_hex_by_coord(neighbor_coord)
			if neighbor != null:
				neighbors.append(neighbor)
			
		hex.neighbors = neighbors

func _find_hex_by_coord(coord: Dictionary) -> Hex:
	for hex in _grid:
		if hex.coord.q == coord.q and hex.coord.r == coord.r and hex.coord.s == coord.s:
			return hex
	return null

func _generate_hex_coords() -> Array:
	var coords = []
	for q in range(-map_size, map_size + 1):
		var r1 = max(-map_size, -q - map_size)
		var r2 = min(map_size, -q + map_size)
		for r in range(r1, r2 + 1):
			coords.append({"q": q, "r": r, "s": -q - r})
	return coords

func _hex_to_3d(q: float, r: float) -> Vector3:
	var x = hex_size * (1.5 * q)
	var z = hex_size * (sqrt(3.0) * (r + q * 0.5))
	return Vector3(x, 0, z)

func _remove_random_hexes() -> void:
	if (_grid.size() > 2):
		for i in range(holes_to_remove):
			var random_index = (randi() % (_grid.size() - 1)) + 1
			var hex_to_remove = _grid[random_index]

			if hex_to_remove.index == player_start_index:
				continue

			hex_to_remove.traversable = false

func _create_visual_elements() -> void:
	for hex in _grid:
		if hex.traversable:
			_grid_container.add_child(hex)
		
			if show_labels:
				var label_position = Vector3(hex.get_location().x, 0.3, hex.get_location().z)

				var index_label = Utilities.create_label(hex.index, label_position)
				index_label.rotate(Vector3(1,0,0), 30)
				index_label.translate(Vector3(0,-0.06,0))

				var cubic_q_label = Utilities.create_label(hex.coord.q, label_position, Color.BLACK)
				cubic_q_label.font_size = 72
				cubic_q_label.rotate(Vector3(1,0,0), 30)
				cubic_q_label.translate(Vector3(0,0.45,0))

				var cubic_r_label = Utilities.create_label(hex.coord.r, label_position)
				cubic_r_label.font_size = 72
				cubic_r_label.rotate(Vector3(1,0,0), 30)
				cubic_r_label.translate(Vector3(-0.4,-0.45,0))

				var cubic_s_label = Utilities.create_label(hex.coord.s, label_position)
				cubic_s_label.font_size = 72
				cubic_s_label.rotate(Vector3(1,0,0), 30)
				cubic_s_label.translate(Vector3(0.4,-0.45,0))

				_grid_container.add_child(index_label)
				_grid_container.add_child(cubic_q_label)
				_grid_container.add_child(cubic_r_label)
				_grid_container.add_child(cubic_s_label)

func _setup_pathfinding() -> void:
	_astar = AStar3D.new()

	# Add points
	for hex in _grid:
		if hex.traversable:
			_astar.add_point(hex.index, hex.location)
	
	# Connect points
	for hex in _grid:
		if hex.traversable:
			for neighbor in hex.neighbors:
				if _astar.has_point(neighbor.index) and not _astar.are_points_connected(hex.index, neighbor.index):
					_astar.connect_points(hex.index, neighbor.index)
	
	if show_astar:
		_astar_debug.visualize_astar(_astar)

func update_pathfinding() -> void:
	_astar.clear()

	# Add points
	for hex in _grid:
		if hex.traversable:
			_astar.add_point(hex.index, hex.location)
	
	# Connect points
	for hex in _grid:
		if hex.traversable:
			for neighbor in hex.neighbors:
				if _astar.has_point(neighbor.index) and not _astar.are_points_connected(hex.index, neighbor.index):
					_astar.connect_points(hex.index, neighbor.index)
	
	if show_astar:
		_astar_debug.visualize_astar(_astar)

# Public methods
func find_path(from_index: int, to_index: int) -> Array[Hex]:
	if not _astar or not _astar.has_point(from_index) or not _astar.has_point(to_index):
		return []
	
	var path_points = _astar.get_point_path(from_index, to_index, true)
	var hex_path: Array[Hex] = []
	
	for point in path_points:
		hex_path.append(get_hex_at_position(point))
	
	return hex_path

func find_path_positions(from_index: int, to_index: int) -> PackedVector3Array:
	var hex_path = find_path(from_index, to_index)
	var positions = PackedVector3Array()
	
	for hex in hex_path:
		positions.append(hex.get_location())
	
	return positions

func get_hex_by_index(index: int) -> Hex:
	for hex in _grid:
		if hex.index == index:
			return hex
	return null

func get_hex_at_position(world_pos: Vector3) -> Hex:
	var closest_hex: Hex = null
	var closest_distance = INF
	
	for hex in _grid:
		var distance = world_pos.distance_to(hex.get_location())
		if distance < closest_distance:
			closest_distance = distance
			closest_hex = hex
	
	return closest_hex

func get_grid() -> Array[Hex]:
	return _grid

func get_traversable_grid() -> Array[Hex]:
	return _grid.filter(func(hex: Hex): 
		return hex.traversable
	)

func set_map_size(size: int) -> void:
	map_size = size
	if _initialized:
		clear()
		initialize()

func set_hex_size(size: float) -> void:
	hex_size = size
	if _initialized:
		clear()
		initialize()

func set_holes(holes: int) -> void:
	holes_to_remove = holes
	if _initialized:
		clear()
		initialize()

func set_show_labels(_show: bool) -> void:
	show_labels = _show
	if _initialized:
		for child in _grid_container.get_children():
			if child is Label3D:
				child.visible = _show

func is_initialized() -> bool:
	return _initialized

func _on_update_grid() -> void:
	_setup_pathfinding()
