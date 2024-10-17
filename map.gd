extends Node3D

const ORIENTATION = {
	"f0": 3.0 / 2.0,
	"f1": 0.0,
	"f2": sqrt(3.0) / 2.0,
	"f3": sqrt(3.0),
	"b0": 2.0 / 3.0,
	"b1": 0.0,
	"b2": -1.0 / 3.0,
	"b3": sqrt(3.0) / 3.0,
	"startAngle": 0.0
}

var SIZE = 40
var ORIGIN = Vector2(0, 0)
var LAYOUT = layout(SIZE, ORIGIN)
var HEX_SIZE = 0.55

@export var MAP_SIZE = 5

var DIRECTIONS = {
	"northWest": hex(-1, 0, 1),
	"north": hex(0, -1, 1),
	"northEast": hex(1, -1, 0),
	"southWest": hex(-1, 1, 0),
	"south": hex(0, 1, -1),
	"southEast": hex(1, 0, -1),
}

var HEX_SCENE = preload("res://hex.tscn")
var PLAYER_SCENE = preload("res://player.tscn")
var ENEMY_SCENE = preload("res://enemy.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var grid = draw_grid()
	draw_players(grid)
	var astar = AStar3D.new()
	var i = 0
	for hex in grid:
		astar.add_point(hex.index, hex.vectors, 1)
	for hex in grid:
		for neighbor in hex.neighbors:
			astar.connect_points(hex.index, neighbor)
	print(astar.are_points_connected(1, 18, true))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func create_grid_structure():
	var cubic_grid = hex_shaped_grid(MAP_SIZE)
	var meters_grid = create_grid_3d_coords(cubic_grid)
	var merged_grid = []
	var i = 0
	for cubic_coord in cubic_grid:
		var tile_data = {
			"cubic": cubic_coord,
			"vectors": meters_grid[i],
			"neighbors": find_hex_matches(cubic_grid, get_all_neighbors(cubic_coord)),
			"index": i
		}
		merged_grid.append(tile_data)
		i = i + 1
	return merged_grid

func draw_grid():
	var grid = create_grid_structure()
	print(grid)
	for hex in grid:
		var hex_mesh = HEX_SCENE.instantiate()
		add_child(hex_mesh)
		hex_mesh.global_transform.origin = hex.vectors
		var label3d = Label3D.new()
		label3d.position = Vector3(hex.vectors.x, 0.3, hex.vectors.z)
		label3d.text = str(hex.index)
		label3d.font_size = 48
		label3d.modulate = Color(0,0,0,1)
		add_child(label3d)
	return grid

func draw_players(grid_coords):
	var player_mesh = PLAYER_SCENE.instantiate()
	var enemy_mesh = ENEMY_SCENE.instantiate()
	add_child(player_mesh)
	add_child(enemy_mesh)
	player_mesh.global_transform.origin = grid_coords[11].vectors
	enemy_mesh.global_transform.origin = grid_coords[12].vectors

func find_hex_matches(large_array: Array, small_array: Array) -> Array:
	var matches = []
	for small_hex in small_array:
		for i in range(large_array.size()):
			var large_hex = large_array[i]
			# Compare all three coordinates
			if large_hex.q == small_hex.q and \
			   large_hex.r == small_hex.r and \
			   large_hex.s == small_hex.s:
				matches.append(i)
				break  # Found match for this hex, move to next
	return matches

func hex(q, r, s):
	if q + r + s != 0:
		push_error("q + r + s must equal 0")
	
	return {"q": q, "r": r, "s": s}

func frac_hexagon(q, r, s):
	if round(q + r + s) != 0:
		push_error("q + r + s must equal 0")
	
	return {"q": q, "r": r, "s": s}

func are_hexagons_equal(hex_a, hex_b):
	return hex_a == hex_b

func add_hex(hex_a, hex_b):
	return hex(hex_a["q"] + hex_b["q"], hex_a["r"] + hex_b["r"], hex_a["s"] + hex_b["s"])

func subtract_hex(hex_a, hex_b):
	return hex(hex_a["q"] - hex_b["q"], hex_a["r"] - hex_b["r"], hex_a["s"] - hex_b["s"])

func multiply_hex(h, multiply_by):
	return hex(h["q"] * multiply_by, h["r"] * multiply_by, h["s"] * multiply_by)

func length_of_hex(h):
	return (abs(h["q"]) + abs(h["r"]) + abs(h["s"])) / 2

func distance_between_hexes(hex_a, hex_b):
	return length_of_hex(subtract_hex(hex_a, hex_b))

func hex_neighbor(h, direction):
	return add_hex(h, direction)

func get_all_neighbors(h):
	var neighbors = []
	for direction in DIRECTIONS.values():
		neighbors.append(hex_neighbor(h, direction))
	return neighbors

func point(x, y):
	return Vector2(x, y)

func layout(size, origin):
	return {
		"size": Vector2(size, size),
		"origin": Vector2(origin.x, origin.y)
	}

func convert_hex_to_pixel(hex):
	var M = ORIENTATION
	var x = (M["f0"] * hex["q"] + M["f1"] * hex["r"]) * LAYOUT["size"].x
	var y = (M["f2"] * hex["q"] + M["f3"] * hex["r"]) * LAYOUT["size"].y
	return point(floor(x + LAYOUT["origin"].x), floor(y + LAYOUT["origin"].y))

func convert_pixel_to_hex(pixel_point):
	var M = ORIENTATION
	var pt = point(
		(pixel_point.x - LAYOUT["origin"].x) / LAYOUT["size"].x,
		(pixel_point.y - LAYOUT["origin"].y) / LAYOUT["size"].y
	)
	var q = M["b0"] * pt.x + M["b1"] * pt.y
	var r = M["b2"] * pt.x + M["b3"] * pt.y
	return hex(round(q), round(r), round(-q - r))

func get_corner_offset(corner):
	var size = LAYOUT["size"]
	var angle = (2.0 * PI * (ORIENTATION["startAngle"] + corner)) / 6
	return point(floor(size.x * cos(angle)), floor(size.y * sin(angle)))

func hex_corners(h):
	var corners = []
	var center = convert_hex_to_pixel(h)
	for i in range(6):
		var offset = get_corner_offset(i)
		corners.append(point(center.x + offset.x, center.y + offset.y))
	return corners

func round_hex(frac_hex):
	var q = round(frac_hex["q"])
	var r = round(frac_hex["r"])
	var s = round(frac_hex["s"])
	return hex(q, r, s)

func hex_lerp(a, b, t):
	return round_hex(frac_hexagon(lerp(a["q"], b["q"], t), lerp(a["r"], b["r"], t), lerp(a["s"], b["s"], t)))

func hex_line(hex_a, hex_b):
	var n = distance_between_hexes(hex_a, hex_b)
	var step = 1.0 / max(n, 1)
	
	var results = []
	for i in range(n + 1):
		results.append(hex_lerp(hex_a, hex_b, i * step))
	return results

func hex_shaped_grid(radius):
	var grid = []
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			grid.append(hex(q, r, -q - r))
	return grid

func hex_shaped_hash_grid(radius):
	var grid = {}
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			var new_hex = hex(q, r, -q - r)
			var hex_string = str(new_hex)
			grid[hex_string] = {
				"neighbors": get_all_neighbors(new_hex),
				"props": {}
			}
	return grid

func shuffle_grid(grid):
	var size = grid.size() / 4
	var new_grid = grid.duplicate()
	for i in range(size):
		new_grid.remove(randi_range(0, grid.size() - 1))
	return new_grid

func hex_to_3d(q, r, s):
	var x = HEX_SIZE * (3.0 / 2.0 * q)
	var z = HEX_SIZE * (sqrt(3.0) * (r + q / 2.0))
	var y = 0  # Can add elevation here if needed
	return Vector3(x, y, z)

func create_grid_3d_coords(cubic_coords):
	var grid = []
	for hex_coord in cubic_coords:
		var q = hex_coord["q"]
		var r = hex_coord["r"]
		var s = hex_coord["s"]
		var position_3d = hex_to_3d(q, r, s)
		grid.append(position_3d)
	return grid
