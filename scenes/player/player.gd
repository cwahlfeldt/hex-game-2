class_name Player
extends Character

func _ready() -> void:
	super()
	id = "player_0"
	type = CHARACTER_TYPE.PLAYER
	move_range = 3
	
