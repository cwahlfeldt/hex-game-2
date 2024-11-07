extends Node3D
class_name Unit

enum UnitType {PLAYER, GRUNT, ARCHER, BOMBER, WIZARD}
enum AttackRangeType {MELEE, RANGED_DIAGONAL, RANGED_COLUMN, RANGED_EXPLOSION, RANGED_CROSS, ALL_WITHIN_DISTANCE}

var type: UnitType = UnitType.PLAYER
var attack_range_type = AttackRangeType.MELEE
var attack_range: int = 1
var attack_power: int = 1
var max_health: int = 3
var move_range: int = 1
var current_health: int = max_health
var current_hex: Hex = null

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= amount

func heal(amount: int) -> void:
	current_health += amount

# func move_to(locations: Array[Vector3], callback: Callable) -> void:
# 	AnimationManager.through_with_callback_and_rotate(
# 		self,
# 		locations,
# 		callback.bind(self)
# 	)
