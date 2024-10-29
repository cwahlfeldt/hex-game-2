class_name Enemy
extends Unit

func _ready() -> void:
	super()
	type = UNIT_TYPE.GRUNT
	max_health = 1
