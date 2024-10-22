extends Node3D

var player_scene = preload("res://scenes/player/player.tscn")
var enemy_scene = preload("res://scenes/enemy/enemy.tscn")
var player
var enemy1
var enemy2
var enemy3
var hex_grid
var path_finding: AStar3D
var player_path_id
var new_position = 50
var path = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.selected_hex.connect(_on_selected_hex)
	var hex_grid_init = HexGrid.initialize()
	hex_grid = hex_grid_init.grid
	path_finding = hex_grid_init.astar
	player_path_id = 50
	
	player = init_player(path_finding.get_point_position(player_path_id))
	enemy1 = init_enemy(path_finding.get_point_position(14))
	enemy2 = init_enemy(path_finding.get_point_position(34))
	enemy3 = init_enemy(path_finding.get_point_position(80))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#player.global_transform.origin = path_finding.get_point_path(player_path_id, new_position)
#

func _on_selected_hex(hex):
	new_position = hex.index
	print(path_finding.get_point_path(player_path_id, new_position))


func init_player(location: Vector3):
	var player = player_scene.instantiate()
	add_child(`bal_transform.origin = location
	return player


func init_enemy(location: Vector3):
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_transform.origin = location
	return enemy
