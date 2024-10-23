extends Node3D

class_name TurnQueue

# Array to store entities in the queue
var queue: Array = []
var current_index: int = 0

# Signal emitted when turn changes
signal turn_changed(entity)

func _init():
	queue = []
	current_index = 0

# Add an entity to the queue
func add_entity(entity) -> void:
	queue.append(entity)

# Remove an entity from the queue
func remove_entity(entity) -> void:
	var entity_index = queue.find(entity)
	if entity_index != -1:
		queue.remove_at(entity_index)
		# Adjust current_index if needed
		if entity_index < current_index:
			current_index -= 1
		elif current_index >= queue.size():
			current_index = 0

# Get the entity whose turn it currently is
func get_current() -> Node:
	if queue.is_empty():
		return null
	return queue[current_index]

# Advance to the next turn
func next_turn() -> void:
	if queue.is_empty():
		return
		
	current_index = (current_index + 1) % queue.size()
	emit_signal("turn_changed", get_current())

# Reset the queue to the beginning
func reset() -> void:
	current_index = 0
	if not queue.is_empty():
		emit_signal("turn_changed", get_current())

# Clear all entities from the queue
func clear() -> void:
	queue.clear()
	current_index = 0

# Get the number of entities in the queue
func size() -> int:
	return queue.size()

# Check if the queue is empty
func is_empty() -> bool:
	return queue.is_empty()
