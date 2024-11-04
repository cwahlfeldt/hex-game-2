extends Node3D
class_name Unit

enum UNIT_TYPE {PLAYER, GRUNT, ARCHER, BOMBER, WIZARD}
enum ATK_RANGE_TYPE {MELEE, RANGED_DIAGONAL, RANGED_COLUMN, RANGED_EXPLOSION, RANGED_CROSS, ALL_WITHIN_DISTANCE}

var type: UNIT_TYPE = UNIT_TYPE.PLAYER
var atk_range_type: ATK_RANGE_TYPE = ATK_RANGE_TYPE.MELEE
var in_atk_range: bool = false
var current_hex: Hex = null
var max_health: int = 3
var move_range: int = 1
var atk_range: int = 1
var current_health: int = max_health

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= amount

func heal(amount: int) -> void:
	current_health += amount
