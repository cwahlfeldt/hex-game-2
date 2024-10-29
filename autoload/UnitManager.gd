extends Node3D

const player_scene = preload("res://scenes/Player/Player.tscn")
const enemy_scene = preload("res://scenes/Enemy/Enemy.tscn")

var player: Player
var enemies: Array[Enemy]

#func _ready() -> void:

	
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

#func _on_players_turn_start(player: Unit):
	#HexGridManager.get_grid().map(func(h: Hex):
		#h.unhighlight()
	#)
#
#func _on_players_turn_end(player: Unit):
	#player.current_hex.neighbors.map(func(n: Hex):
		#n.highlight('blue')
	#)
