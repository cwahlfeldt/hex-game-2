extends Node3D

const player_scene = preload("res://scenes/Player/Player.tscn")
const enemy_scene = preload("res://scenes/Enemy/Enemy.tscn")

var player: Player
var enemies: Array[Enemy]

func spawn_player(hex: Hex):
	player = player_scene.instantiate()
	var unit = _spawn(player, hex)
	return unit

func spawn_enemy(hex: Hex):
	var enemy = enemy_scene.instantiate()
	var unit = _spawn(enemy, hex)
	enemies.append(unit)
	unit.name = "Enemy_" + str(enemies.size())
	return unit

func _spawn(unit, hex: Hex):
	#print("Spawning ", unit.name, " at hex: ", hex.index)  # Debug starting hex
	add_child(unit)
	unit.global_position = hex.location
	unit.current_hex = hex
	HexGridManager.get_instance().register_unit(unit, hex)
	
	# Verify the hex after registration
	#print(unit.name, " final hex: ", unit.current_hex.index)  # Debug final hex
	return unit

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
