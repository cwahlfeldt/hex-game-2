class_name Animate
extends Node

# Singleton instance
static var instance: Animate

# Default animation settings
const DEFAULT_DURATION: float = 0.15
const DEFAULT_DELAY: float = 0.0
const DEFAULT_TRANS: Tween.TransitionType = Tween.TRANS_CUBIC
const DEFAULT_EASE: Tween.EaseType = Tween.EASE_IN_OUT

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


# Static methods for position tweening
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


# Helper methods for tween management
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


# Configuration creators for common animation types
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
