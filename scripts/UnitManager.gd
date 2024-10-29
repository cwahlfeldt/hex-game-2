extends Node3D

const player_scene = preload("res://scenes/player/player.tscn")
const enemy_scene = preload("res://scenes/enemy/enemy.tscn")

var player: Player
var enemies: Array[Enemy]

func spawn_player(hex: Hex):
	player = player_scene.instantiate()
	_spawn(player, hex)
	return player

func spawn_enemy(hex: Hex):
	var enemy = enemy_scene.instantiate()
	_spawn(enemy, hex)
	enemies.append(enemy)
	enemy.name = "Enemy_" + str(enemies.size())
	return enemy

func _spawn(scene, hex: Hex):
	scene.current_hex = hex
	add_child(scene)
	scene.global_transform.origin = hex.location

func get_player():
	return player

func get_enemies():
	return enemies
