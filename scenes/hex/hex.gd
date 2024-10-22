extends Node3D

@export var hex_obj = {}

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if (event.is_pressed() && event.is_action("Left Mouse Click")):
		SignalBus.selected_hex.emit(hex_obj)
