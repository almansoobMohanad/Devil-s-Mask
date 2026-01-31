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
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.collider is CharacterBody3D:
			var player = collision.collider
			player.take_damage(deal_damage())

func go_to_player(player_position: Vector3) -> void:
	var direction := (player_position - global_transform.origin).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func deal_damage() -> int:
	return damage

func die() -> void:
	queue_free()
