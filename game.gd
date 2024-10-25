extends Node3D

const player_scene = preload("res://scenes/player/player.tscn")
const enemy_scene = preload("res://scenes/enemy/enemy.tscn")

@onready var hex_grid_manager: HexGridManager = $HexGridManager
var players_id = 0
var hex_grid
var path_finding: AStar3D
var rng = RandomNumberGenerator.new()
var turn_queue: TurnQueue = TurnQueue.new()
var is_moving = false
var current_character: Character  # Keep track of current character

func _ready() -> void:
	SignalBus.selected_hex.connect(_on_selected_hex)
	hex_grid_manager.configure({
		"map_size": 5,
		"show_labels": true,
		"holes_to_remove": 12
	})

	hex_grid = hex_grid_manager.get_grid()
	path_finding = hex_grid_manager._astar
	
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
		print(to_hex)
		move_character(character, character.current_hex_id, to_hex)

func _on_turn_changed(entity: Character):
	print("It's now " + entity.id + "'s turn!  ", entity.path, "  ", entity.current_hex_id)
	if entity and entity.name != 'Player':
		print("SHOULD_WORK: ", entity.current_hex_id, ", ", players_id)
		move_character(entity, entity.current_hex_id, players_id)
	else:
		is_moving = false

func _on_character_move_end():
	turn_queue.next_turn()

func move_character(character: Character, from_hex, to_hex):
	print("TO_HEX: ", to_hex)
	var path = hex_grid_manager.find_path(from_hex, to_hex)
	if path.size() > 1:
		character.path = path.slice(0, character.move_range + 1) # account for current hex
		var current_hex = hex_grid_manager.get_hex_at_position(character.path[character.path.size() - 1])
		character.current_hex_id = current_hex.index
		players_id = current_hex.index
		Animate.through_with_callback(
			character, 
			character.path,
			_on_character_move_end,
		)
		is_moving = true
		print("Path set for ", character.name, ": ", character.path)

func init_player(index: int) -> Character:
	var player: Character = player_scene.instantiate()
	var location = hex_grid_manager.get_hex_by_index(index).position
	print(location)
	player.current_hex_id = index
	players_id = index
	add_child(player)
	player.global_transform.origin = location
	return player

func init_enemy(preferred_index: int) -> Character:
	var valid_indices = get_valid_spawn_indices()
	var actual_index = preferred_index
	
	# If preferred index doesn't exist, pick a random valid one
	if not path_finding.has_point(preferred_index) or not valid_indices.has(preferred_index):
		# Remove player's position from valid spawn points
		valid_indices.erase(players_id)
		if valid_indices.size() > 0:
			actual_index = valid_indices[randi() % valid_indices.size()]
		else:
			push_error("No valid spawn points for enemy!")
			return null
	
	var enemy: Character = enemy_scene.instantiate()
	var location = hex_grid_manager.get_hex_by_index(actual_index).position
	enemy.current_hex_id = actual_index
	add_child(enemy)
	enemy.global_transform.origin = location
	return enemy
	
func get_valid_spawn_indices() -> Array:
	# Get array of valid hex indices that exist in the grid
	var valid_indices = []
	for hex in hex_grid:
		valid_indices.append(hex.index)
	return valid_indices
