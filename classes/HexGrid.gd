class_name HexGrid
extends Node3D

const HEX_SCENE = preload("res://scenes/Hex/Hex.tscn")

const DIRECTIONS = {
	"northWest": {"q": -1, "r": 0, "s": 1},
	"north": {"q": 0, "r": -1, "s": 1},
	"northEast": {"q": 1, "r": -1, "s": 0},
	"southWest": {"q": -1, "r": 1, "s": 0},
	"south": {"q": 0, "r": 1, "s": -1},
	"southEast": {"q": 1, "r": 0, "s": -1}
}

@export_group("Grid Configuration")
@export var map_size: int = 5
@export var hex_size: float = 1.1

var _grid: Array[Hex] = []
var _astar: AStar3D
var _grid_container: Node3D

func _ready() -> void:
	_setup_grid_container()

func _setup_grid_container() -> void:
	_grid_container = Node3D.new()
	_grid_container.name = "HexGridContainer"
	add_child(_grid_container)

# Core Grid Generation
func initialize() -> void:
	clear()
	_generate_grid()
	_generate_neighbors()
	_setup_pathfinding()

func _generate_grid() -> void:
	var hex_coords = _generate_hex_coords()
	_sort_coords(hex_coords)
	
	for i in hex_coords.size():
		var coord = hex_coords[i]
		var location = _hex_to_3d(coord.q, coord.r)
		
		var hex = _create_hex_instance(i, coord, location)
		_grid.append(hex)
		_grid_container.add_child(hex)

func _generate_hex_coords() -> Array:
	var coords = []
	for q in range(-map_size, map_size + 1):
		var r1 = max(-map_size, -q - map_size)
		var r2 = min(map_size, -q + map_size)
		for r in range(r1, r2 + 1):
			coords.append({"q": q, "r": r, "s": -q - r})
	return coords

func _sort_coords(coords: Array) -> void:
	coords.sort_custom(func(a, b):
		if a.r != b.r:
			return a.r > b.r
		return a.q > b.q
	)

func _create_hex_instance(index: int, coord: Dictionary, location: Vector3) -> Hex:
	var hex_data = {
		"index": index,
		"coord": coord,
		"location": location,
		"neighbors": [],
	}
	
	var hex = HEX_SCENE.instantiate() as Hex
	hex.name = "Hex_%d" % index
	hex.set_data(hex_data)
	return hex

func _generate_neighbors() -> void:
	for hex in _grid:
		var neighbors: Array = []
		for direction in DIRECTIONS.values():
			var neighbor_coord = {
				"q": hex.coord.q + direction.q,
				"r": hex.coord.r + direction.r,
				"s": hex.coord.s + direction.s
			}
			var neighbor = _find_hex_by_coord(neighbor_coord)
			if neighbor != null:
				neighbors.append(neighbor)
		hex.neighbors = neighbors

# Core Pathfinding
func _setup_pathfinding() -> void:
	_astar = AStar3D.new()
	_add_astar_points()
	_connect_astar_points()

func _add_astar_points() -> void:
	for hex in _grid:
		if hex.traversable:
			_astar.add_point(hex.index, hex.location)

func _connect_astar_points() -> void:
	for hex in _grid:
		if not hex.traversable:
			continue
		
		for neighbor in hex.neighbors:
			if _astar.has_point(neighbor.index) and not _astar.are_points_connected(hex.index, neighbor.index):
				_astar.connect_points(hex.index, neighbor.index)

# Utility Methods
func _hex_to_3d(q: float, r: float) -> Vector3:
	var x = hex_size * (1.5 * q)
	var z = hex_size * (sqrt(3.0) * (r + q * 0.5))
	return Vector3(x, 0, z)

func _find_hex_by_coord(coord: Dictionary) -> Hex:
	for hex in _grid:
		if hex.coord.q == coord.q and hex.coord.r == coord.r and hex.coord.s == coord.s:
			return hex
	return null

# Public Methods
func get_hex_by_index(index: int) -> Hex:
	return _grid.filter(func(hex): return hex.index == index).front()

func get_hex_at_position(world_pos: Vector3) -> Hex:
	return _grid.reduce(
		func(closest: Hex, current: Hex) -> Hex:
			return current if world_pos.distance_to(current.get_location()) < world_pos.distance_to(closest.get_location()) else closest,
		_grid[0]
	)

func find_path(from_index: int, to_index: int) -> Array[Hex]:
	if not _is_valid_path(from_index, to_index):
		return []
	
	var path_points = _astar.get_point_path(from_index, to_index, true)
	var hex_path: Array[Hex] = []
	
	# Convert the Vector3 points to Hex objects
	for point in path_points:
		hex_path.append(get_hex_at_position(point))
	
	return hex_path

func get_grid() -> Array[Hex]:
	return _grid

func get_traversable_grid() -> Array[Hex]:
	return _grid.filter(func(hex): return hex.traversable)

func _is_valid_path(from_index: int, to_index: int) -> bool:
	return _astar and _astar.has_point(from_index) and _astar.has_point(to_index)

func clear() -> void:
	for hex in _grid:
		hex.queue_free()
	_grid.clear()
	_astar = null

# Returns the distance between two hexes using cube coordinates
func get_hex_distance(hex_a: Hex, hex_b: Hex) -> int:
	var a = hex_a.coord
	var b = hex_b.coord
	return int((abs(a.q - b.q) + abs(a.r - b.r) + abs(a.s - b.s)) / 2)

# Gets the ring of hexes at exactly distance N from center
func get_hex_ring(center: Hex, radius: int) -> Array[Hex]:
	var results: Array[Hex] = []
	
	for hex in _grid:
		if hex.traversable and get_hex_distance(center, hex) == radius:
			results.append(hex)
			
	return results
