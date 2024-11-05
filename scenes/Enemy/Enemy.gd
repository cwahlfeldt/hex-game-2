class_name Enemy
extends Unit

var _highlighted_hexes: Array[Hex] = []

func _ready() -> void:
	super()
	
	name = 'Enemy'
	type = UNIT_TYPE.GRUNT
	max_health = 1
	move_range = 1
	current_health = 1
	
# Call this when a unit is selected
func show_movement_range() -> void:
	clear_highlights()

	var available_moves = HexGridManager.get_available_moves(current_hex, move_range)
	for hex in available_moves:
		hex.highlight("r") # Using blue channel for movement range
		_highlighted_hexes.append(hex)

# Call this to clear highlights (when deselecting unit or after movement)
func clear_highlights() -> void:
	for hex in _highlighted_hexes:
		hex.unhighlight()
	_highlighted_hexes.clear()
