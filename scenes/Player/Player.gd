extends Unit
class_name Player

func _ready() -> void:
	super()
	SignalBus.connect("players_turn", _on_players_turn)
	SignalBus.connect("players_turn_end", _on_players_turn_end)
	
	name = "Player"
	type = UNIT_TYPE.PLAYER
	move_range = 1

func _on_players_turn(player: Unit, is_first_turn = false):
	if is_first_turn:
		player.current_hex.neighbors.map(func(n: Hex):
			n.highlight('b')
		)
	else:
		HexGridManager.get_grid().map(func(h: Hex):
			h.unhighlight()
		)
	
func _on_players_turn_end(player: Unit):
	player.current_hex.neighbors.map(func(n: Hex):
		n.highlight('b')
	)
