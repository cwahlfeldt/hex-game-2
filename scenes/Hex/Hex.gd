# hex.gd
class_name Hex
extends Node3D

# Hex data - make these explicitly typed
var index: int = -1
var coord: Dictionary = {"q": 0, "r": 0, "s": 0}  # Cube coordinates
var location: Vector3 = Vector3.ZERO  # Renamed from position to avoid conflicts
var neighbors: Array = []  # Renamed and typed
var traversable: bool = true

func _ready() -> void:
	# SignalBus.turn_end.connect(_on_turn_end)
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
func get_neighbor_indices() -> Array:
	return neighbors

func get_coordinate() -> Dictionary:
	return coord
	
func get_location() -> Vector3:
	return location

# Optional: Add visual feedback for selection/hover
func highlight(color) -> void:
	var material = $HexMesh/Cylinder.get_surface_override_material(0)
	var unique_material = material.duplicate()
	unique_material.albedo_color[color] = 255
	$HexMesh/Cylinder.set_surface_override_material(0, unique_material)

func unhighlight() -> void:
	var material: StandardMaterial3D = $HexMesh/Cylinder.get_surface_override_material(0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.4
	material.albedo_color.r = 1
	material.albedo_color.g = 1
	material.albedo_color.b = 1

# You might want to add methods for handling clicks or other interactions
func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if (event.is_pressed() && event.is_action("Left Mouse Click")):
		SignalBus.selected_hex.emit(self)

# func _on_turn_end(u):
# 	print(u.name)
