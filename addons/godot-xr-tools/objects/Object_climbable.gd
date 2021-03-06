class_name Object_climbable
extends Spatial

##
## Climbable Object
##
## @desc:
##     This script adds climbing support to any StaticBody.
##
##     For climbing to work, the player must have a Function_Climb_movement.
##

var press_to_hold := true

## Dictionary of grab locations by pickup
var grab_transforms := {}

# Called by Function_pickup
func is_picked_up():
	return false

# Called by Function_pickup when user presses the action button while holding this object
func action():
	pass

# Called by Function_pickup when this becomes the closest object to a controller
func increase_is_closest():
	pass

# Called by Function_pickup when this stops being the closest object to a controller
func decrease_is_closest():
	pass

# Called by Function_pickup when this is picked up by a controller
func pick_up(by: Function_Pickup, with_controller: ARVRController):
	save_grab_transform(by)

# Called by Function_pickup when this is let go by a controller
func let_go(p_linear_velocity: Vector3, p_angular_velocity: Vector3):
	pass

# Save the grab transform
func save_grab_transform(p: Function_Pickup):
	grab_transforms[p.get_instance_id()] = p.global_transform

func get_grab_transform(p: Function_Pickup) -> Transform:
	return grab_transforms[p.get_instance_id()]

# Get the grab location in world-space
func get_grab_location(p: Function_Pickup) -> Vector3:
	return get_grab_transform(p).origin
