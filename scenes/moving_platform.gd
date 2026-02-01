extends StaticBody3D

@export var distance: float = 5.0  # Distance to move back and forth
@export var speed: float = 2.0  # Speed of movement
@export var axis: Vector3 = Vector3.RIGHT  # Direction to move (X, Y, or Z axis)
@export var start_offset: float = 0.0  # Random start position (0-1)

var start_position: Vector3
var time_passed: float = 0.0

func _ready():
	start_position = global_position
	time_passed = start_offset * PI * 2.0

func _physics_process(delta):
	time_passed += delta * speed
	
	# Calculate offset using sine wave for smooth back-and-forth motion
	var offset = sin(time_passed) * distance
	
	# Calculate new position
	var target_position = start_position + (axis.normalized() * offset)
	
	# Apply movement
	global_position = target_position
