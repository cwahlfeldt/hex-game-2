extends Unit
class_name Player

func _ready() -> void:
	super()
	SignalBus.connect("players_turn_start", _on_players_turn_start)
	SignalBus.connect("players_turn_end", _on_players_turn_end)
	
	name = "Player"
	type = UNIT_TYPE.PLAYER

func _on_players_turn_start(player: Unit):
	HexGridManager.get_grid().map(func(h: Hex):
		h.unhighlight()
	)

func _on_players_turn_end(player: Unit):
	player.current_hex.neighbors.map(func(n: Hex):
		n.highlight('b')
	)
