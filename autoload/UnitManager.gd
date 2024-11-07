extends Node3D

const player_scene = preload("res://scenes/Player/Player.tscn")
const enemy_scene = preload("res://scenes/Enemy/Enemy.tscn")

var _player_unit: Player
var _enemy_units: Array[Unit] = []
var _unit_positions: Dictionary = {} # Unit -> Hex mapping
var _hex_units: Dictionary = {} # Hex -> Array[Unit] mapping

func spawn_player(hex: Hex):
	_player_unit = player_scene.instantiate()
	var unit = _spawn(_player_unit, hex)
	return unit

func spawn_enemy(hex: Hex):
	var enemy = enemy_scene.instantiate()
	var unit = _spawn(enemy, hex)
	_enemy_units.append(enemy)
	unit.name = "Enemy_" + str(_enemy_units.size())
	return unit

func _spawn(unit, hex: Hex):
	add_child(unit)
	unit.global_position = hex.location
	unit.current_hex = hex
	_register_unit(unit, hex)
	return unit

func _register_unit(unit: Unit, hex: Hex) -> void:
	if not _unit_positions.has(unit):
		_unit_positions[unit] = hex
		if not _hex_units.has(hex):
			_hex_units[hex] = []
		_hex_units[hex].append(unit)
		unit.current_hex = hex
		unit.global_position = hex.location
		SignalBus.unit_registered.emit(unit)

func _unregister_unit(unit: Unit) -> void:
	if _unit_positions.has(unit):
		var current_hex = _unit_positions[unit]
		_hex_units[current_hex].erase(unit)
		if _hex_units[current_hex].is_empty():
			_hex_units.erase(current_hex)
		_unit_positions.erase(unit)
		SignalBus.unit_unregistered.emit(unit)

func move_unit(unit: Unit, to_hex: Hex) -> void:
	var from_hex = unit.current_hex
	
	if from_hex == to_hex:
		return
	
	var available_moves = HexGridManager.get_available_moves(from_hex, unit.move_range)
	if available_moves.is_empty():
		SignalBus.turn_end.emit(unit)
		return
	
	var target_hex: Hex = HexGridManager.find_target_hex(from_hex, to_hex, unit)
	var path = HexGridManager.find_path(from_hex.index, target_hex.index)
	
	_update_unit_position(unit, from_hex, target_hex)
	
	var locations: Array[Vector3] = []
	for hex in path:
		locations.append(hex.location)
	
	AnimationManager.through_with_callback_and_rotate(
		unit,
		locations,
		func():
			SignalBus.unit_moved.emit(unit)
	)

func _update_unit_position(unit: Unit, from_hex: Hex, target_hex: Hex) -> void:
	if from_hex and _hex_units.has(from_hex):
		_hex_units[from_hex].erase(unit)
		if _hex_units[from_hex].is_empty():
			_hex_units.erase(from_hex)
	
	_unit_positions[unit] = target_hex
	unit.current_hex = target_hex
	
	if not _hex_units.has(target_hex):
		_hex_units[target_hex] = []
	_hex_units[target_hex].append(unit)

func get_hex_units():
	return _hex_units

func has_units(hex: Hex) -> bool:
	return _hex_units.has(hex) and not _hex_units[hex].is_empty()

func get_units_in_attack_range(from_unit: Unit, attack_range: int) -> Array[Unit]:
	var units_in_range: Array[Unit] = []
	var from_hex = from_unit.current_hex
	
	# Loop through our existing hex_units dictionary
	for hex in _hex_units:
		# Simple hex distance check
		if HexGridManager.get_hex_distance(from_hex, hex) <= attack_range:
			# Add all units on this hex except the attacking unit
			for unit in _hex_units[hex]:
				if unit != from_unit:
					units_in_range.append(unit)
	
	return units_in_range

func get_enemies() -> Array[Unit]:
	return _enemy_units

func get_all_units() -> Array:
	return [_player_unit] + _enemy_units
