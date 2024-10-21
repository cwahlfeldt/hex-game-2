extends Node3D

const RAY_LENGTH = 1000.0

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		  var camera3d = $Camera3D
		  var from = camera3d.project_ray_origin(event.position)
		  var to = from + camera3d.project_ray_normal(event.position) * RAY_LENGTH
