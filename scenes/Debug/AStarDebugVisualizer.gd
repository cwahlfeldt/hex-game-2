# AStarDebugVisualizer.gd
extends Node3D
class_name AStarDebugVisualizer

# Configuration
@export var point_size: float = 0.2
@export var line_thickness: float = 0.05
@export var active_color: Color = Color.GREEN
@export var disabled_color: Color = Color.RED
@export var connection_color: Color = Color.CYAN
@export var opacity: float = 0.8

# Internal variables
var _debug_points: Node3D
var _debug_connections: Node3D
var _point_mesh: Mesh
var _connection_mesh: Mesh
var _active_material: StandardMaterial3D
var _disabled_material: StandardMaterial3D
var _connection_material: StandardMaterial3D

func _ready() -> void:
	_setup_materials()
	_setup_containers()
	_create_meshes()

func _setup_materials() -> void:
	# Material for active points
	_active_material = StandardMaterial3D.new()
	_active_material.no_depth_test = true
	_active_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_active_material.albedo_color = active_color
	_active_material.albedo_color.a = opacity
	_active_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	
	# Material for disabled points
	_disabled_material = StandardMaterial3D.new()
	_disabled_material.no_depth_test = true
	_disabled_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_disabled_material.albedo_color = disabled_color
	_disabled_material.albedo_color.a = opacity
	_disabled_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	
	# Material for connections
	_connection_material = StandardMaterial3D.new()
	_connection_material.no_depth_test = true
	_connection_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_connection_material.albedo_color = connection_color
	_connection_material.albedo_color.a = opacity
	_connection_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA

func _setup_containers() -> void:
	_debug_points = Node3D.new()
	_debug_points.name = "DebugPoints"
	add_child(_debug_points)
	
	_debug_connections = Node3D.new()
	_debug_connections.name = "DebugConnections"
	add_child(_debug_connections)

func _create_meshes() -> void:
	# Create sphere mesh for points
	_point_mesh = SphereMesh.new()
	_point_mesh.radius = point_size
	_point_mesh.height = point_size * 2
	
	# Create cylinder mesh for connections
	_connection_mesh = CylinderMesh.new()
	_connection_mesh.top_radius = line_thickness
	_connection_mesh.bottom_radius = line_thickness
	_connection_mesh.height = 1.0  # Will be scaled to match distance

func clear() -> void:
	for child in _debug_points.get_children():
		child.queue_free()
	for child in _debug_connections.get_children():
		child.queue_free()

func visualize_astar(astar: AStar3D) -> void:
	clear()
	
	var points = astar.get_point_ids()
	
	# Draw connections first (so they appear behind points)
	for point_id in points:
		var from_pos = astar.get_point_position(point_id)
		var connections = astar.get_point_connections(point_id)
		
		for connected_point in connections:
			var to_pos = astar.get_point_position(connected_point)
			_draw_connection(from_pos, to_pos)
	
	# Then draw points
	for point_id in points:
		var pos = astar.get_point_position(point_id)
		var is_disabled = astar.is_point_disabled(point_id)
		_draw_point(pos, is_disabled)

func _draw_point(point: Vector3, is_disabled: bool) -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _point_mesh
	mesh_instance.material_override = _disabled_material if is_disabled else _active_material
	mesh_instance.position = point
	_debug_points.add_child(mesh_instance)

func _draw_connection(from_pos: Vector3, to_pos: Vector3) -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _connection_mesh
	mesh_instance.material_override = _connection_material
	
	# Calculate the middle point and look at target
	var distance = from_pos.distance_to(to_pos)
	mesh_instance.position = from_pos.lerp(to_pos, 0.5)
	mesh_instance.look_at_from_position(mesh_instance.position, to_pos, Vector3.UP)
	mesh_instance.rotate_object_local(Vector3.RIGHT, PI/2)
	
	# Scale the cylinder to match the distance
	mesh_instance.scale = Vector3(1, distance, 1)
	
	_debug_connections.add_child(mesh_instance)
