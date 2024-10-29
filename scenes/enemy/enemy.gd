class_name Enemy
extends Character

#const enemy_scene = preload("res://scenes/enemy/enemy.tscn")

func _ready() -> void:
	super()
	id = "grunt_0"
	type = CHARACTER_TYPE.GRUNT
	max_health = 1

#func spawn(hex: Hex) -> Enemy:
	#var player = enemy_scene.instantiate()
	#return spawn_unit(player, hex)
