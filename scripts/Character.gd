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
@export var current_hex: Hex = null

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

func move_unit(to_hex: Hex, _callback) -> void:
	var new_path = HexGridManager.find_path(current_hex.index, to_hex.index)
	if new_path.size() > 1:
		var path = new_path.slice(0, move_range + 1) # account for current hex
		current_hex = path[path.size() - 1]
	
		var locations: Array[Vector3]
		locations.assign(path.map(func(hex) -> Vector3: return hex.location))
		
		AnimationManager.through_with_callback_and_rotate(
			self,
			locations,
			_callback.bind(current_hex),
		)
