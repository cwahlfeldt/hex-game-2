# hex.gd
class_name Hex
extends Node3D

# Hex data - make these explicitly typed
var index: int = -1
var coord: Dictionary = {"q": 0, "r": 0, "s": 0}  # Cube coordinates
var location: Vector3 = Vector3.ZERO  # Renamed from position to avoid conflicts
var neighbors: Array[int] = []  # Renamed and typed

func _ready() -> void:
	global_transform.origin = location
# Use set_data instead of _init
func set_data(data: Dictionary) -> void:
	if data.is_empty():
		return
		
	index = data.index
	coord = data.coord
	location = data.location
	neighbors = data.neighbors

# Helper methods
func get_neighbor_indices() -> Array[int]:
	return neighbors

func get_coordinate() -> Dictionary:
	return coord
	
func get_location() -> Vector3:
	return location

# Optional: Add visual feedback for selection/hover
func highlight() -> void:
	# Implement highlighting logic
	# For example, change material color
	pass

func unhighlight() -> void:
	# Reset highlighting
	pass

# You might want to add methods for handling clicks or other interactions
func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, shape_idx: int) -> void:
	if (event.is_pressed() && event.is_action("Left Mouse Click")):
		SignalBus.selected_hex.emit(self)
