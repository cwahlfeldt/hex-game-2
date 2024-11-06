extends HexGrid

var show_labels: bool = true
var show_astar: bool = true
var holes_to_remove: int = 8
var player_start_index: int:
	get: return map_size + 2

var _astar_debug: AStarDebugVisualizer

func _ready() -> void:
	SignalBus.selected_hex.connect(_on_selected_hex)

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
	
	SignalBus.grid_initialized.emit()

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

func get_available_moves(from_hex: Hex, move_range: int) -> Array[Hex]:
	var available: Array[Hex] = []
	for hex in _grid:
		if not hex.traversable or UnitManager.has_units(hex) or hex == from_hex:
			continue
		
		var path = find_path(from_hex.index, hex.index)
		if path.size() > 1 and path.size() - 1 <= move_range:
			available.append(hex)
	
	return available

# Triggers the players turn
func _on_selected_hex(hex: Hex):
	var unit = TurnManager.get_current()
	if unit.type == Unit.UNIT_TYPE.PLAYER:
		SignalBus.player_turn.emit(unit, hex)
