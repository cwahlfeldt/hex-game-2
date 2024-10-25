extends Node3D

class_name Character

signal health_changed(new_health, max_health)
signal character_died(id)

enum CHARACTER_TYPE {PLAYER, GRUNT}

@onready var hex_grid_manager: HexGridManager = $HexGridManager

@export var id: String = "character_0"
@export var type: CHARACTER_TYPE = CHARACTER_TYPE.PLAYER
@export var max_health: int = 3
@export var move_range: int = 1
@export var atk_range: int = 1
@export var current_hex_id: int = 0
@export var path: PackedVector3Array = [Vector3(0,0,0), ]:
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

func move_unit(to_hex: int, _callback) -> void:
	var new_path = hex_grid_manager.find_path(current_hex_id, to_hex)
	
	if path.size() > 1:
		path = new_path.slice(0, move_range + 1) # account for current hex
		var current_hex = hex_grid_manager.get_hex_at_position(path[path.size() - 1])
		current_hex_id = current_hex.index
		
		Animate.through_with_callback_and_rotate(
			self,
			path,
			_callback.bind(current_hex.index),
		)
