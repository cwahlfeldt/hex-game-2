extends Unit
class_name Player

var _highlighted_hexes: Array[Hex] = []

func _ready() -> void:
	super()
	name = "Player"
	type = UNIT_TYPE.PLAYER
	atk_range_type = ATK_RANGE_TYPE.MELEE
	move_range = 1

# Call this when a unit is selected
func show_movement_range(unit: Unit) -> void:
	clear_highlights()
	
	var available_moves = HexGridManager.get_available_moves(unit.current_hex, unit.move_range)
	for hex in available_moves:
		hex.highlight("b") # Using blue channel for movement range
		_highlighted_hexes.append(hex)

# Call this to clear highlights (when deselecting unit or after movement)
func clear_highlights() -> void:
	for hex in _highlighted_hexes:
		hex.unhighlight()
	_highlighted_hexes.clear()
