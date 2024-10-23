extends Node3D

const player_scene = preload("res://scenes/player/player.tscn")
const enemy_scene = preload("res://scenes/enemy/enemy.tscn")

#var player: Character
var hex_grid
var path_finding: AStar3D
var player_start_hex_id = 50
var player_path_id = 50
var path = []
var enemy_path = []
var is_player_turn = true
var enemies = []
var rng = RandomNumberGenerator.new()
var turn_queue: TurnQueue = TurnQueue.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.selected_hex.connect(_on_selected_hex)
	var hex_grid_init = HexGrid.initialize()
	hex_grid = hex_grid_init.grid
	path_finding = hex_grid_init.astar
	
	var player = init_player(50)
	turn_queue.add_entity(player)
	
	enemies = range(3).map(func(n):
		var enemy = init_enemy(n)
		turn_queue.add_entity(enemy)
	)
	
	turn_queue.turn_changed.connect(_on_turn_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var current_character: Character = turn_queue.get_current()
	if current_character.path.size() > 1:
		Animate.through_with_callback(current_character, current_character.path, _on_player_move_end)


func _on_turn_changed(entity):
	print("It's now " + entity.name + "'s turn!")


func _on_player_move_end():
	var current_character: Character = turn_queue.get_current()
	var current_hex_id = path_finding.get_closest_point(current_character.path[1])
	current_character.current_hex_id = current_hex_id
	current_character.path = []
	turn_queue.next_turn()


func _on_selected_hex(hex):
	var current_character: Character = turn_queue.get_current()
	current_character.path = path_finding.get_point_path(current_character.current_hex_id, hex.index).slice(0, 2)
	var path_ids = range(current_character.path.size()).map(func(i): return path_finding.get_closest_point(current_character.path[i]))
	print(path_ids)


func init_player(id: int):
	var player = player_scene.instantiate()
	var location = path_finding.get_point_position(id)
	player.current_hex_id = id
	add_child(player)
	player.global_transform.origin = location
	return player


func init_enemy(id: int):
	var enemy: Character = enemy_scene.instantiate()
	var location = path_finding.get_point_position(id)
	enemy.current_hex_id = id
	add_child(enemy)
	enemy.global_transform.origin = location
	return enemy
