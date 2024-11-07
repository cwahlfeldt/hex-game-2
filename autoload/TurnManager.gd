extends Node3D

var _turn_queue: Array = []
var _current_index: int = 0
var _turns_taken: int = 0

func _ready() -> void:
	_turn_queue = []
	_current_index = 0
	SignalBus.turn_end.connect(_on_turn_end)
	SignalBus.unit_registered.connect(_on_unit_registered)
	SignalBus.unit_unregistered.connect(_on_unit_unregistered)

# Add an entity to the _turn_queue
func add_entity(entity) -> void:
	_turn_queue.append(entity)

# Remove an entity from the _turn_queue
func remove_entity(entity) -> void:
	var entity_index = _turn_queue.find(entity)
	if entity_index != -1:
		_turn_queue.remove_at(entity_index)
		# Adjust _current_index if needed
		if entity_index < _current_index:
			_current_index -= 1
		elif _current_index >= _turn_queue.size():
			_current_index = 0 

# Get the entity whose turn it currently is
func get_current() -> Node3D:
	if _turn_queue.is_empty():
		return null
	return _turn_queue[_current_index]

func get_next() -> Node3D:
	if _turn_queue.is_empty():
		return null
	var next_index = (_current_index + 1) % _turn_queue.size()
	return _turn_queue[next_index]

# Get all entities in the _turn_queue
func get_all_entities() -> Array:
	if _turn_queue.is_empty():
		return []
	return _turn_queue

# Advance to the next turn
func next_turn() -> void:
	if _turn_queue.is_empty():
		return
		
	_current_index = (_current_index + 1) % _turn_queue.size()
	_handle_all_turns()
	SignalBus.turn_change.emit(get_current())

# Reset the _turn_queue to the beginning
func reset() -> void:
	_current_index = 0
	if not _turn_queue.is_empty():
		SignalBus.turn_change.emit(get_current())

# Clear all entities from the _turn_queue
func clear() -> void:
	_turn_queue.clear()
	_current_index = 0

# Get the number of entities in the _turn_queue
func size() -> int:
	return _turn_queue.size()

# Check if the _turn_queue is empty
func is_empty() -> bool:
	return _turn_queue.is_empty()

func _handle_all_turns():
	_turns_taken += 1
	if _turns_taken == _turn_queue.size():
		_turns_taken = 0
		SignalBus.all_turns_end.emit(get_all_entities())
	
func _on_turn_end(_last_unit: Unit) -> void:
	pass
	# var current_unit = get_current()
	
	# # Handle signals based on unit types
	# if last_unit.type == Unit.UNIT_TYPE.PLAYER:
	# 	SignalBus.player_turn_end.emit(last_unit)
	# 	SignalBus.turn_end.emit(last_unit)
	# 	# Start enemy sequence after player
	# 	if current_unit.type != Unit.UNIT_TYPE.PLAYER:
	# 		SignalBus.turn_start.emit(current_unit)
	# 		SignalBus.enemy_turn.emit(current_unit)
	# else:
	# 	SignalBus.enemy_turn_end.emit(last_unit)
	# 	SignalBus.turn_end.emit(last_unit)
	# 	# Only chain to next enemy if there is one
	# 	if current_unit and current_unit.type != Unit.UNIT_TYPE.PLAYER:
	# 		SignalBus.turn_start.emit(current_unit)
	# 		SignalBus.enemy_turn.emit(current_unit)
	


func is_unit_turn(unit: Unit) -> bool:
	return get_current() == unit

func _on_unit_registered(unit) -> void:
	add_entity(unit)

func _on_unit_unregistered(unit) -> void:
	remove_entity(unit)
		
