extends Node3D

var current_hex = {}
var health = 2

func _ready() -> void:
	SignalBus.selected_hex.connect(_on_select_hex)


func _on_select_hex(hex):
	current_hex = hex
	print(current_hex)
