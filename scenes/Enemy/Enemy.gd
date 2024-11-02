class_name Enemy
extends Unit

func _ready() -> void:
	super()
	SignalBus.connect("enemy_turn", _on_enemy_turn_start)
	SignalBus.connect("enemy_turn_end", _on_enemy_turn_end)
	
	type = UNIT_TYPE.GRUNT
	max_health = 1

func _on_enemy_turn_start(_enemy: Unit):
	HexGridManager.get_instance().get_grid().map(func(h: Hex):
		if h.traversable == true:
			h.unhighlight()
	)

func _on_enemy_turn_end(enemy: Unit):
	enemy.current_hex.neighbors.map(func(n: Hex):
		n.highlight('r')
	)
