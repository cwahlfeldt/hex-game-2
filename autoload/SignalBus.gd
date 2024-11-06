extends Node3D

# Game Management
@warning_ignore("unused_signal") signal start_game()

# Grid Management
@warning_ignore("unused_signal") signal grid_initialized()
@warning_ignore("unused_signal") signal selected_hex(hex: Hex)

# Turn Management
@warning_ignore("unused_signal") signal turn_start(unit: Unit)
@warning_ignore("unused_signal") signal turn_change(unit: Unit)
@warning_ignore("unused_signal") signal turn_end(unit: Unit)
@warning_ignore("unused_signal") signal unit_turn_end(unit: Unit)
@warning_ignore("unused_signal") signal player_turn(unit: Unit)
@warning_ignore("unused_signal") signal player_turn_end(unit: Unit)
@warning_ignore("unused_signal") signal enemy_turn(unit: Unit)
@warning_ignore("unused_signal") signal enemy_turn_end(unit: Unit)
@warning_ignore("unused_signal") signal all_turns_end(units: Array[Unit])

# Unit Management
@warning_ignore("unused_signal") signal unit_moved(unit: Unit, from_hex: Hex, to_hex: Hex)
@warning_ignore("unused_signal") signal unit_registered(unit: Unit)
@warning_ignore("unused_signal") signal unit_unregistered(unit: Unit)
