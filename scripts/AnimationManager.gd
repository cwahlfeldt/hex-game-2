extends Node3D

# Default animation settings
const DEFAULT_DURATION: float = 0.15
const DEFAULT_DELAY: float = 0.0
const DEFAULT_TRANS: Tween.TransitionType = Tween.TRANS_CUBIC
const DEFAULT_EASE: Tween.EaseType = Tween.EASE_IN_OUT
const DEFAULT_ROTATION_DURATION: float = 0.1  # Quick rotation by default

# Dictionary to store active tweens for each node
static var active_tweens: Dictionary = {}

class TweenConfig:
	var duration: float = DEFAULT_DURATION
	var delay: float = DEFAULT_DELAY
	var trans_type: Tween.TransitionType = DEFAULT_TRANS
	var ease_type: Tween.EaseType = DEFAULT_EASE
	
	func _init(
		p_duration: float = DEFAULT_DURATION,
		p_trans: Tween.TransitionType = DEFAULT_TRANS,
		p_ease: Tween.EaseType = DEFAULT_EASE,
		p_delay: float = DEFAULT_DELAY
	):
		duration = p_duration
		trans_type = p_trans
		ease_type = p_ease
		delay = p_delay

# New rotation methods
static func look_at_position(
	node: Node3D, 
	target_pos: Vector3,
	config: TweenConfig = TweenConfig.new(DEFAULT_ROTATION_DURATION)
) -> Tween:
	if target_pos == node.global_position:
		return null
		
	_kill_tween(node)
	var tween = _create_tween(node, config)
	
	var target_basis = node.global_transform.looking_at(target_pos, Vector3.UP).basis
	tween.tween_property(
		node,
		"basis",
		target_basis,
		config.duration
	)
	
	return tween

# Combined rotation and movement
static func look_at_and_move_to(
	node: Node3D,
	target_pos: Vector3,
	movement_config: TweenConfig = TweenConfig.new()
) -> Tween:
	_kill_tween(node)
	var tween = _create_tween(node, movement_config)
	
	# First rotate quickly
	if target_pos != node.global_position:
		var target_basis = node.global_transform.looking_at(target_pos, Vector3.UP).basis
		tween.tween_property(
			node,
			"basis",
			target_basis,
			DEFAULT_ROTATION_DURATION
		)
	
	# Then move
	tween.tween_property(
		node,
		"position",
		target_pos,
		movement_config.duration
	)
	
	return tween

# Enhanced through positions with rotation
static func through_with_rotation(
	node: Node3D,
	positions: Array[Vector3],
	config: TweenConfig = TweenConfig.new(),
	loop: bool = false
) -> Tween:
	if positions.is_empty():
		return null
		
	_kill_tween(node)
	var tween = _create_tween(node, config)
	
	var points_to_use = positions.duplicate()
	if loop and positions.size() > 1:
		points_to_use.append(positions[0])
	
	for point in points_to_use:
		# Quick rotation to face next point
		if point != node.global_position:
			var target_basis = node.global_transform.looking_at(point, Vector3.UP).basis
			tween.tween_property(
				node,
				"basis",
				target_basis,
				DEFAULT_ROTATION_DURATION
			)
		
		# Move to point
		tween.tween_property(
			node,
			"position",
			point,
			config.duration
		)
		
		if config.delay > 0:
			tween.tween_interval(config.delay)
	
	if loop:
		tween.set_loops()
	
	return tween

# Existing methods remain unchanged...
static func to(node: Node3D, target: Vector3, config: TweenConfig = TweenConfig.new()) -> Tween:
	_kill_tween(node)
	var tween = _create_tween(node, config)
	
	tween.tween_property(
		node,
		"position",
		target,
		config.duration
	)
	
	return tween

static func through(
	node: Node3D, 
	positions: Array[Vector3], 
	config: TweenConfig = TweenConfig.new(),
	loop: bool = false
) -> Tween:
	if positions.is_empty():
		return null
		
	_kill_tween(node)
	var tween = _create_tween(node, config)
	
	var points_to_use = positions.duplicate()
	if loop and positions.size() > 1:
		points_to_use.append(positions[0])
	
	for point in points_to_use:
		tween.tween_property(
			node,
			"position",
			point,
			config.duration
		)
		
		if config.delay > 0:
			tween.tween_interval(config.delay)
	
	if loop:
		tween.set_loops()
	
	return tween

static func through_with_callback(
	node: Node3D, 
	positions: Array[Vector3], 
	callback: Callable,
	config: TweenConfig = TweenConfig.new(),
	loop: bool = false
) -> Tween:
	var tween = through(node, positions, config, loop)
	if tween and not loop:
		tween.tween_callback(callback)
	return tween

static func through_with_callback_and_rotate(
	node: Node3D, 
	positions: Array[Vector3], 
	callback: Callable,
	config: TweenConfig = TweenConfig.new(),
	loop: bool = false
) -> Tween:
	var tween = through_with_rotation(node, positions, config, loop)
	if tween and not loop:
		tween.tween_callback(callback)
	return tween

# Helper methods
static func _kill_tween(node: Node) -> void:
	if active_tweens.has(node) and is_instance_valid(active_tweens[node]):
		active_tweens[node].kill()
	active_tweens.erase(node)

static func _create_tween(node: Node, config: TweenConfig) -> Tween:
	var tween = node.create_tween()
	tween.set_trans(config.trans_type)
	tween.set_ease(config.ease_type)
	active_tweens[node] = tween
	return tween

# Configuration creators
static func config(
	duration: float = DEFAULT_DURATION,
	trans: Tween.TransitionType = DEFAULT_TRANS,
	ease: Tween.EaseType = DEFAULT_EASE,
	delay: float = DEFAULT_DELAY
) -> TweenConfig:
	return TweenConfig.new(duration, trans, ease, delay)

static func smooth(duration: float = DEFAULT_DURATION) -> TweenConfig:
	return TweenConfig.new(duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

static func bouncy(duration: float = DEFAULT_DURATION) -> TweenConfig:
	return TweenConfig.new(duration, Tween.TRANS_BOUNCE, Tween.EASE_OUT)

static func quick(duration: float = 0.3) -> TweenConfig:
	return TweenConfig.new(duration, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
