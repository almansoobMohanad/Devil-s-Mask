extends CharacterBody3D

const SPEED := 10.0
var damage : int = 1
var health : int = 3


func _physics_process(delta: float) -> void:
    # Add the gravity.
    if not is_on_floor():
        velocity += get_gravity() * delta

    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    go_to_player(get_node("/root/Player").global_transform.origin)

    move_and_slide()

func go_to_player(player_position: Vector3) -> void:
    var direction := (player_position - global_transform.origin).normalized()
    velocity.x = direction.x * SPEED
    velocity.z = direction.z * SPEED
    move_and_slide()

func damage_player():
    pass