extends Node3D

const player_scene = preload("res://scenes/player/player.tscn")
const enemy_scene = preload("res://scenes/enemy/enemy.tscn")

var hex_grid
var path_finding: AStar3D
var player_start_hex_id = 50
var rng = RandomNumberGenerator.new()
var turn_queue: TurnQueue = TurnQueue.new()
var current_character: Character  # Keep track of current character

func _ready() -> void:
	SignalBus.selected_hex.connect(_on_selected_hex)
	var hex_grid_init = HexGrid.initialize()
	hex_grid = hex_grid_init.grid
	path_finding = hex_grid_init.astar
	
	var player = init_player(50)
	turn_queue.add_entity(player)
	
	range(3).map(func(n):
		var enemy = init_enemy(rng.randi_range(0, 40))
		turn_queue.add_entity(enemy)
	)
	
	turn_queue.turn_changed.connect(_on_turn_changed)
	current_character = turn_queue.get_current()  # Initialize current character

func _process(delta: float) -> void:
	if current_character and current_character.path.size() > 1:
		# Use global_transform.origin for proper position access
		current_character.global_transform.origin = current_character.path[1]
		#Animate.through_with_callback(
			#current_character, 
			#current_character.path, 
			#_on_player_move_end,
		#)

func _on_turn_changed(entity):
	print("It's now " + entity.name + "'s turn!")
	current_character = entity  # Update current character reference

func _on_player_move_end():
	if current_character and current_character.path.size() > 1:
		current_character.current_hex_id = path_finding.get_closest_point(current_character.path[1])
		#current_character.path = []
		turn_queue.next_turn()
		current_character = turn_queue.get_current()  # Update reference after turn change

func _on_selected_hex(hex):
	if current_character:
		var path = path_finding.get_point_path(current_character.current_hex_id, hex.index)
		if path.size() >= 2:
			current_character.path = path.slice(0, 2)
			print("Path set for ", current_character.name, ": ", current_character.path)

func init_player(id: int) -> Character:
	var player: Character = player_scene.instantiate()
	var location = path_finding.get_point_position(id)
	player.current_hex_id = id
	add_child(player)
	player.global_transform.origin = location
	return player

func init_enemy(id: int) -> Character:
	var enemy: Character = enemy_scene.instantiate()
	var location = path_finding.get_point_position(id)
	enemy.current_hex_id = id
	add_child(enemy)
	enemy.global_transform.origin = location
	return enemy
