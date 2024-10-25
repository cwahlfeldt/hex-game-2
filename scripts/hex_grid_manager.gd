class_name HexGridManager
extends Node3D

const HEX_SCENE = preload("res://scenes/hex/hex.tscn")

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
@export var show_labels: bool = true
@export var holes_to_remove: int = 8
@export var auto_initialize: bool = true  # Add this to control automatic initialization

var _grid: Array[Hex] = []
var _astar: AStar3D
var _initialized: bool = false

func _ready() -> void:
	if auto_initialize:
		initialize()

# New configuration method
func configure(config: Dictionary = {}) -> void:
	# Update configuration if provided
	if config.has("map_size"):
		map_size = config.map_size
	if config.has("hex_size"):
		hex_size = config.hex_size
	if config.has("show_labels"):
		show_labels = config.show_labels
	if config.has("holes_to_remove"):
		holes_to_remove = config.holes_to_remove
	
	# If already initialized, rebuild the grid
	if _initialized:
		clear()
		initialize()

# Clear current grid
func clear() -> void:
	# Remove all child nodes (hex meshes and labels)
	for child in get_children():
		child.queue_free()
	
	_grid.clear()
	_astar = null
	_initialized = false

func initialize() -> void:
	clear()
	_grid = _generate_grid()
	_setup_pathfinding()
	_initialized = true

func _generate_grid() -> Array[Hex]:
	# Generate base hex coordinates
	var hex_coords = _generate_hex_coords()
	hex_coords.sort_custom(func(a, b):
		if a.r != b.r:
			return a.r > b.r  # Sort by r coordinate (reverse)
		return a.q > b.q 
	)     # Then by q coordinate (reverse)
	
	# Convert to 3D positions and create grid data
	var grid = _create_grid_data(hex_coords)
	
	# Remove random hexes while maintaining connectivity
	grid = _remove_random_hexes(grid)
	
	# Instantiate visual elements
	_create_visual_elements(grid)
	
	return grid

func _generate_hex_coords() -> Array:
	var coords = []
	for q in range(-map_size, map_size + 1):
		var r1 = max(-map_size, -q - map_size)
		var r2 = min(map_size, -q + map_size)
		for r in range(r1, r2 + 1):
			coords.append({"q": q, "r": r, "s": -q - r})
	return coords

func _create_grid_data(hex_coords: Array) -> Array[Hex]:
	var grid: Array[Hex] = []
	
	for i in hex_coords.size():
		var coord = hex_coords[i]
		var location = _hex_to_3d(coord.q, coord.r)
		
		var neighbors: Array[int] = []
		for direction in DIRECTIONS.values():
			var neighbor_coord = {
				"q": coord.q + direction.q,
				"r": coord.r + direction.r,
				"s": coord.s + direction.s
			}
			var neighbor_index = _find_hex_index(hex_coords, neighbor_coord)
			if neighbor_index != -1:
				neighbors.append(neighbor_index)
		
		## Create data dictionary for hex initialization
		var hex_data = {
			"index": i,
			"coord": coord,
			"location": location,
			"neighbors": neighbors
		}
		
		# Create new Hex instance
		var hex_instance = HEX_SCENE.instantiate() as Hex
		hex_instance.set_data(hex_data)
		grid.append(hex_instance)
	
	return grid


func _hex_to_3d(q: float, r: float) -> Vector3:
	# Optimized conversion using precalculated constants
	var x = hex_size * (1.5 * q)
	var z = hex_size * (sqrt(3.0) * (r + q * 0.5))
	return Vector3(x, 0, z)

func _find_hex_index(coords: Array, coord: Dictionary) -> int:
	for i in coords.size():
		var c = coords[i]
		if c.q == coord.q and c.r == coord.r and c.s == coord.s:
			return i
	return -1

func _remove_random_hexes(grid: Array[Hex]) -> Array[Hex]:
	var working_grid = grid.duplicate()
	var removed = 0
	
	while removed < holes_to_remove:
		# Skip if we're down to minimum size
		if working_grid.size() <= 2:
			break
			
		var random_index = (randi() % (working_grid.size() - 1)) + 1
		var hex_to_remove = working_grid[random_index]
		
		if hex_to_remove.index == 0:
			continue
			
		working_grid.remove_at(random_index)
		
		if _is_grid_connected(working_grid):
			removed += 1
		else:
			working_grid.insert(random_index, hex_to_remove)
	
	return working_grid

func _is_grid_connected(grid: Array[Hex]) -> bool:
	if grid.size() <= 1:
		return true
	
	var visited = {}
	var to_visit = [grid[0]]
	
	while to_visit.size() > 0:
		var current = to_visit.pop_back()
		visited[current.index] = true
		
		for neighbor_index in current.get_neighbor_indices():
			for hex in grid:
				if hex.index == neighbor_index and not visited.has(hex.index):
					to_visit.append(hex)
	
	return visited.size() == grid.size()

func _create_visual_elements(grid: Array[Hex]) -> void:
	for hex in grid:
		add_child(hex)
		hex.global_transform.origin = hex.position
		
		if show_labels:
			var label = Label3D.new()
			label.position = Vector3(hex.position.x, 0.3, hex.position.z)
			label.text = str(hex.index)
			label.font_size = 90
			label.rotate(Vector3(1,0,0), 30)
			label.translate(Vector3(0,0.5,0))
			label.modulate = Color.BLACK
			add_child(label)

func _setup_pathfinding() -> void:
	_astar = AStar3D.new()
	
	# Add points
	for hex in _grid:
		_astar.add_point(hex.index, hex.position)
	
	# Connect points
	for hex in _grid:
		for neighbor_index in hex.get_neighbor_indices():
			if _astar.has_point(neighbor_index) and not _astar.are_points_connected(hex.index, neighbor_index):
				_astar.connect_points(hex.index, neighbor_index)

# Public methods
func find_path(from_index: int, to_index: int) -> PackedVector3Array:
	if not _astar or not _astar.has_point(from_index) or not _astar.has_point(to_index):
		return PackedVector3Array()
	return _astar.get_point_path(from_index, to_index)

func get_hex_by_index(index: int) -> Hex:
	for hex in _grid:
		if hex.index == index:
			return hex
	return null

func get_hex_at_position(world_pos: Vector3) -> Hex:
	var closest_hex: Hex = null
	var closest_distance = INF
	
	for hex in _grid:
		var distance = world_pos.distance_to(hex.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_hex = hex
	
	return closest_hex

func get_grid() -> Array[Hex]:
	return _grid
	
# Add getter/setter methods for runtime configuration
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
		# Just update labels without rebuilding grid
		for child in get_children():
			if child is Label3D:
				child.visible = show

# Add status check
func is_initialized() -> bool:
	return _initialized
