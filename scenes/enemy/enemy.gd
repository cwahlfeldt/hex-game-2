class_name Enemy
extends Character

func _ready() -> void:
	super()
	id = "grunt_0"
	type = CHARACTER_TYPE.GRUNT
	max_health = 1
	move_range = 3
