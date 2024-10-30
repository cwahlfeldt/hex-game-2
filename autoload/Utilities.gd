extends Node3D

func create_label(text, pos, color = Color.BLACK) -> Label3D:
	var label = Label3D.new()
	label.position = pos
	label.text = str(text)
	label.font_size = 90
	label.modulate = color
	return label
