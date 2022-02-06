class_name VelocityAverager


##
## Velocity Averager class
##
## @desc:
##     This class assists in calculating the average velocity of an object.
##     It accepts the following three types of input:
##      - Periodic distances
##      - Periodic positions
##      - Periodic velocities
##
##     It provides the average velocity calculated from the total distance 
##     divided by the total time.
## 


# Count of samples to keep
var _count: int

# Array of times-steps
var _deltas := Array()

# Array of distances
var _distances := Array()

# Last position (if using periodic positions)
var _last_position : Vector3

# Indicates whether the last position is valid
var _has_last_position := false


## Initialize the AverageVelocity with a count of the samples to average over
func _init(var count: int):
	_count = count

## Clear the velocity averager
func clear():
	_deltas.clear()
	_distances.clear()

## Add a distance to the averager
func add_distance(delta: float, var distance: Vector3):
	# Add delta and distance to averaging arrays
	_distances.push_back(distance)
	_deltas.push_back(delta)

	# Keep the number of samples down to the requested count
	if _distances.size() > _count:
		_distances.pop_front()
		_deltas.pop_front()

## Add a position to the averager
func add_position(delta: float, var position: Vector3):
	# Handle first position
	if !_has_last_position:
		_last_position = position
		_has_last_position = true
		return
	
	# Convert position to distance and add
	var distance := position - _last_position
	_last_position = position
	add_distance(delta, distance)

## Add a velocity to the averager
func add_velocity(delta: float, var velocity: Vector3):
	# Convert velocity to distance and add
	add_distance(delta, velocity * delta)

## Test if we have data for averaging
func has_velocity() -> bool:
	return _distances.size() > 0

## Return the velocity
func velocity() -> Vector3:
	# Calculate the total time
	var total_time := 0.0
	for dt in _deltas:
		total_time += dt

	# Safety check to prevent division by zero
	if total_time <= 0.0:
		return Vector3.ZERO

	# Calculate the total distance
	var total_distance := Vector3.ZERO
	for dd in _distances:
		total_distance += dd

	# Return the average
	return total_distance / total_time
