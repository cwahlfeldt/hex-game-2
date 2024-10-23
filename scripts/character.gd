extends Node3D

class_name Character

signal health_changed(new_health, max_health)
signal character_died(id)

enum CHARACTER_TYPE {PLAYER, GRUNT}

@export var id: String = "character_0"
@export var type: CHARACTER_TYPE = CHARACTER_TYPE.PLAYER
@export var max_health: int = 3
@export var move_range: int = 1
@export var atk_range: int = 1
@export var current_hex_id: int = 0
@export var path: PackedVector3Array = []:
	set(value):
		path = value
		print("Path set for ", name, ": ", path) 


var current_health: int = max_health:
	set(value):
		current_health = clampi(value, 0, max_health)
		emit_signal("health_changed", current_health, max_health)
		if current_health <= 0:
			emit_signal("character_died", id)

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= amount

func heal(amount: int) -> void:
	current_health += amount

# Add this method to handle position updates
func update_position(new_position: Vector3) -> void:
	global_transform.origin = new_position
