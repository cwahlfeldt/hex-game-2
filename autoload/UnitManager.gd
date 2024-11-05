extends Node3D

const player_scene = preload("res://scenes/Player/Player.tscn")
const enemy_scene = preload("res://scenes/Enemy/Enemy.tscn")

var player: Player
var enemies: Array[Unit] = []
var all_units: Array[Unit] = []

func spawn_player(hex: Hex):
	player = player_scene.instantiate()
	var unit = _spawn(player, hex)
	return unit

func spawn_enemy(hex: Hex):
	var enemy = enemy_scene.instantiate()
	var unit = _spawn(enemy, hex)
	enemies.append(enemy)
	unit.name = "Enemy_" + str(enemies.size())
	return unit

func _spawn(unit, hex: Hex):
	add_child(unit)
	unit.global_position = hex.location
	unit.current_hex = hex
	all_units.append(unit)
	HexGridManager.register_unit(unit, hex)
	return unit

func get_all_units():
	return all_units
