extends Node3D

@warning_ignore("unused_signal") signal selected_hex(hex: Hex)
@warning_ignore("unused_signal") signal turn_change(unit: Unit)
@warning_ignore("unused_signal") signal turn_end(unit: Unit)
@warning_ignore("unused_signal") signal health_changed(new_health: int, max_health: int)
@warning_ignore("unused_signal") signal character_died(unit: Unit)
@warning_ignore("unused_signal") signal players_turn_start(unit: Unit)
@warning_ignore("unused_signal") signal players_turn_end(unit: Unit)
@warning_ignore("unused_signal") signal enemy_turn_start(unit: Unit)
@warning_ignore("unused_signal") signal enemy_turn_end(unit: Unit)
