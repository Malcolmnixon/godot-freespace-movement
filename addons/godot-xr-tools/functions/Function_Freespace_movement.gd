tool
class_name Function_FreeSpaceMovement
extends Node

# Grab state of the free-space movement
enum GrabState {
	NONE,		# No gripper
	LEFT,		# Left gripping
	RIGHT,		# Right gripping
	RELEASED	# Released (transition to NONE after physics)
}

## Movement provider order
export var order := 15

## Pickup function for the left hand
export (NodePath) var left_pickup = null

## Pickup function for the right hand
export (NodePath) var right_pickup = null

## Velocity multiplier when flinging off objects
export var fling_multiplier := 1.0

## Averages for velocity measurement
export var velocity_averages := 10

# Node references
var _left_pickup_node : Function_Pickup = null
var _right_pickup_node : Function_Pickup = null
onready var _origin : ARVROrigin = get_arvr_origin()
onready var _camera : ARVRCamera = get_arvr_camera()
onready var _body : KinematicBody = $KinematicBody

# Grabbing state
var _grab_state = GrabState.NONE
var _climbable : Object_climbable = null
var _grabber : Function_Pickup = null

# Velocity averaging fields
var _old_position := Vector3.ZERO
var _distances = Array()
var _deltas = Array()
var _velocity := Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	# Hook up the left pickup node
	_left_pickup_node = get_node(left_pickup)
	_left_pickup_node.connect("has_picked_up", self, "_left_has_picked_up")
	_left_pickup_node.connect("has_dropped", self, "_left_has_dropped")
	
	# Hook up the right pickup node
	_right_pickup_node = get_node(right_pickup)
	_right_pickup_node.connect("has_picked_up", self, "_right_has_picked_up")
	_right_pickup_node.connect("has_dropped", self, "_right_has_dropped")

func _left_has_picked_up(what):
	var climbable := what as Object_climbable
	if climbable:
		_climbable = climbable
		_grabber = _left_pickup_node
		_grab_state = GrabState.LEFT

func _right_has_picked_up(what):
	var climbable := what as Object_climbable
	if climbable:
		_climbable = climbable
		_grabber = _right_pickup_node
		_grab_state = GrabState.RIGHT

func _left_has_dropped():
	if _grab_state == GrabState.LEFT:
		_climbable = null
		_grabber = null
		_grab_state = GrabState.RELEASED

func _right_has_dropped():
	if _grab_state == GrabState.RIGHT:
		_climbable = null
		_grabber = null
		_grab_state = GrabState.RELEASED

func _physics_process(delta: float):
	# Do not run physics if in the editor
	if Engine.editor_hint:
		return

	# Transport the body to the camera
	_body.global_transform = _camera.global_transform
	var pos_before := _body.global_transform.origin
	
	# Handle any grabbing mechanics
	_handle_grabbing(delta)

	# Perform the move and slide
	_velocity = _body.move_and_slide(_velocity)
	
	# Update the origin
	_origin.global_transform.origin += _body.global_transform.origin - pos_before
	
func _handle_grabbing(delta: float):
	# Calculate the instantaneous velocity
	var position := _camera.global_transform.origin;
	var instantaneous_velocity = position - _old_position
	_old_position = position
	
	# Skip if not grabbing
	if _grab_state == GrabState.NONE:
		return

	# Handle release physics
	if _grab_state == GrabState.RELEASED:
		_grab_state = GrabState.NONE
		_velocity = _average_velocity() * fling_multiplier
		_distances.clear()
		_deltas.clear()
		return

	# Get the left transform
	var grabbed := _climbable.get_grab_transform(_grabber)
	var gripper := _grabber.global_transform
	var transform := grabbed * gripper.inverse()
	_origin.global_transform = (transform * _origin.global_transform).orthonormalized()
	_update_velocity(delta, instantaneous_velocity)

# Update player velocity averaging data
func _update_velocity(delta: float, distance: Vector3):
	# Add delta and distance to averaging arrays
	_distances.push_back(distance)
	_deltas.push_back(delta)
	if _distances.size() > velocity_averages:
		_distances.pop_front()
		_deltas.pop_front()

# Calculate average player velocity
func _average_velocity() -> Vector3:
	# Calculate the total time
	var total_time := 0.0
	for dt in _deltas:
		total_time += dt

	# Calculate the total distance
	var total_distance := Vector3(0.0, 0.0, 0.0)
	for dd in _distances:
		total_distance += dd

	# Return the average
	return total_distance / total_time

# Get our ARVR origin node, we should be in a branch of this
func get_arvr_origin() -> ARVROrigin:
	var parent = get_parent()
	while parent:
		if parent is ARVROrigin:
			return parent
		parent = parent.get_parent()
	
	return null

# Get our ARVR camera
func get_arvr_camera() -> ARVRCamera:
	# Get origin node
	var origin : ARVROrigin = get_arvr_origin()
	if !origin:
		return null

	# Get by default name 
	var node := origin.get_node_or_null("ARVRCamera") as ARVRCamera
	if node:
		return node

	# Find the first camera child
	for child in origin.get_children():
		var child_camera = child as ARVRCamera
		if child_camera:
			return child_camera

	# No camera found under ARVROrigin
	return null
