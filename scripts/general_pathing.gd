extends AnimatableBody3D

@export var path_follow_path : NodePath
@onready var path_follow = get_node(path_follow_path)

const SPEED := 10.0

func _physics_process(delta: float) -> void:
	# Move along the path
	path_follow.progress += SPEED * delta
	global_transform.origin = path_follow.global_transform.origin
	look_at(path_follow.global_transform.origin + path_follow.transform.basis.z, Vector3.UP)
