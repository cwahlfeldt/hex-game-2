extends Node3D

const hex_scene = preload("res://scenes/hex/hex.tscn")

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
var hex_size: float = 1.1
var show_labels: bool = true
var holes_to_remove: int = 8

# Internal variablesd
var _grid: Array[Hex] = []
var _astar: AStar3D
var _initialized: bool = false
var _grid_container: Node3D

func _ready() -> void:
	# Only create the container node, but don't initialize the grid yet
	_grid_container = Node3D.new()
	_grid_container.name = "HexGridContainer"
	add_child(_grid_container)

func configure(config: Dictionary = {}) -> void:
	if config.has("map_size"):
		map_size = config.map_size
	if config.has("hex_size"):
		hex_size = config.hex_size
	if config.has("show_labels"):
		show_labels = config.show_labels
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
		
		var neighbors: Array[int] = []
		for direction in directions.values():
			var neighbor_coord = {
				"q": coord.q + direction.q,
				"r": coord.r + direction.r,
				"s": coord.s + direction.s
			}
			var neighbor_index = _find_hex_index(hex_coords, neighbor_coord)
			if neighbor_index != -1:
				neighbors.append(neighbor_index)
		
		var hex_data = {
			"index": i,
			"coord": coord,
			"location": location,
			"neighbors": neighbors
		}
		
		var hex_instance = hex_scene.instantiate() as Hex
		hex_instance.name = "Hex_" + str(i)
		hex_instance.set_data(hex_data)
		_grid.append(hex_instance)
	
	_remove_random_hexes()
	_create_visual_elements()

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

func _find_hex_index(coords: Array, coord: Dictionary) -> int:
	for i in coords.size():
		var c = coords[i]
		if c.q == coord.q and c.r == coord.r and c.s == coord.s:
			return i
	return -1

func _remove_random_hexes() -> void:
	var removed = 0
	
	while removed < holes_to_remove and _grid.size() > 2:
		var random_index = (randi() % (_grid.size() - 1)) + 1
		var hex_to_remove = _grid[random_index]
		
		if hex_to_remove.index == 0:
			continue
		
		_grid.remove_at(random_index)
		hex_to_remove.queue_free()
		
		if _is_grid_connected():
			removed += 1
		else:
			_grid.insert(random_index, hex_to_remove)

func _is_grid_connected() -> bool:
	if _grid.size() <= 1:
		return true
	
	var visited = {}
	var to_visit = [_grid[0]]
	
	while to_visit.size() > 0:
		var current = to_visit.pop_back()
		visited[current.index] = true
		
		for neighbor_index in current.get_neighbor_indices():
			var neighbor = get_hex_by_index(neighbor_index)
			if neighbor and not visited.has(neighbor.index):
				to_visit.append(neighbor)
	
	return visited.size() == _grid.size()

func _create_visual_elements() -> void:
	for hex in _grid:
		_grid_container.add_child(hex)
		
		if show_labels:
			var label = Label3D.new()
			label.position = Vector3(hex.get_location().x, 0.3, hex.get_location().z)
			label.text = str(hex.index)
			label.font_size = 90
			label.rotate(Vector3(1,0,0), 30)
			label.translate(Vector3(0,0.5,0))
			label.modulate = Color.BLACK
			_grid_container.add_child(label)

func _setup_pathfinding() -> void:
	_astar = AStar3D.new()
	
	# Add points
	for hex in _grid:
		_astar.add_point(hex.index, hex.get_location())
	
	# Connect points
	for hex in _grid:
		for neighbor_index in hex.get_neighbor_indices():
			if _astar.has_point(neighbor_index) and not _astar.are_points_connected(hex.index, neighbor_index):
				_astar.connect_points(hex.index, neighbor_index)

# Public methods
func find_path(from_index: int, to_index: int) -> Array[Hex]:
	if not _astar or not _astar.has_point(from_index) or not _astar.has_point(to_index):
		return []
	
	var path_points = _astar.get_point_path(from_index, to_index)
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

func set_show_labels(show: bool) -> void:
	show_labels = show
	if _initialized:
		for child in _grid_container.get_children():
			if child is Label3D:
				child.visible = show

func is_initialized() -> bool:
	return _initialized
