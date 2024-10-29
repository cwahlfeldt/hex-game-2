class_name Enemy
extends Unit

func _ready() -> void:
	super()
	SignalBus.connect("enemy_turn_start", _on_enemy_turn_start)
	SignalBus.connect("enemy_turn_end", _on_enemy_turn_end)
	
	type = UNIT_TYPE.GRUNT
	max_health = 1

func _on_enemy_turn_start(player: Unit):
	HexGridManager.get_grid().map(func(h: Hex):
		h.unhighlight()
	)

func _on_enemy_turn_end(player: Unit):
	player.current_hex.neighbors.map(func(n: Hex):
		n.highlight('r')
	)
