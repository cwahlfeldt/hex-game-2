extends Node3D

const player_scene = preload("res://scenes/player/player.tscn")
const enemy_scene = preload("res://scenes/enemy/enemy.tscn")

var players_id = 0
var hex_grid
var path_finding: AStar3D
var rng = RandomNumberGenerator.new()
var turn_queue: TurnQueue = TurnQueue.new()
var is_moving = false
var current_character: Character  # Keep track of current character

func _ready() -> void:
	SignalBus.selected_hex.connect(_on_selected_hex)
	var hex_grid_init = HexGrid.initialize()
	hex_grid = hex_grid_init.grid
	path_finding = hex_grid_init.astar
	
	# Set up turn queue with player at start
	turn_queue.add_entity(init_player(players_id))
	range(3).map(func(n):
		var enemy = init_enemy(rng.randi_range(30, hex_grid.size()))
		turn_queue.add_entity(enemy)
	)
	turn_queue.turn_changed.connect(_on_turn_changed)
	print("Its" + turn_queue.get_current().name + "turn")

func _on_selected_hex(to_hex):
	var character: Character = turn_queue.get_current()
	if character and character.name == 'Player' and not is_moving:
		move_character(character, character.current_hex_id, to_hex.index)

func _on_turn_changed(entity: Character):
	print("It's now " + entity.id + "'s turn!  ", entity.path, "  ", entity.current_hex_id)
	if entity and entity.name != 'Player':
		move_character(entity, entity.current_hex_id, players_id)
	else:
		is_moving = false

func _on_character_move_end():
	turn_queue.next_turn()

func move_character(character: Character, from_hex, to_hex):
	var path = path_finding.get_point_path(from_hex, to_hex)
	if path.size() <= character.move_range:
		character.path = path.slice(0, path.size())
		var current_hex = path_finding.get_closest_point(character.path[path.size() - 1])
		character.current_hex_id = current_hex
		players_id = current_hex
		Animate.through_with_callback(
			character, 
			character.path,
			_on_character_move_end,
		)
		is_moving = true
		print("Path set for ", character.name, ": ", character.path)

func init_player(id: int) -> Character:
	var player: Character = player_scene.instantiate()
	var location = path_finding.get_point_position(id)
	player.current_hex_id = id
	players_id = id
	add_child(player)
	player.global_transform.origin = location
	return player


func get_valid_spawn_indices() -> Array:
	# Get array of valid hex indices that exist in the grid
	var valid_indices = []
	for hex in hex_grid:
		valid_indices.append(hex.index)
	return valid_indices

func init_enemy(preferred_id: int) -> Character:
	var valid_indices = get_valid_spawn_indices()
	var actual_id = preferred_id
	
	# If preferred index doesn't exist, pick a random valid one
	if not path_finding.has_point(preferred_id) or not valid_indices.has(preferred_id):
		# Remove player's position from valid spawn points
		valid_indices.erase(players_id)
		if valid_indices.size() > 0:
			actual_id = valid_indices[randi() % valid_indices.size()]
		else:
			push_error("No valid spawn points for enemy!")
			return null
	
	var enemy: Character = enemy_scene.instantiate()
	var location = path_finding.get_point_position(actual_id)
	enemy.current_hex_id = actual_id
	add_child(enemy)
	enemy.global_transform.origin = location
	return enemy
