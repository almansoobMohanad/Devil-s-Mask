extends CharacterBody3D

const SPEED := 10.0
const SIGHT_RANGE := 20.0
const VIEW_ANGLE := 120.0
@onready var ray = $VisionRayCast
@onready var vision_area = $VisionArea

@onready var debug_line = $DebugLine

var health : int = 3
var damage : int = 1
var attack_cooldown : float = 1.0
var attack_timer : float = 0.0

# Scanning parameters
var scan_speed : float = 1.0
var scan_angle : float = 0.0
var scanning : bool = true

# Scanning limits in radians
var scan_min : float = -2 
var scan_max : float = 2
var scan_direction : int = 1 # 1 for right, -1 for left


func _physics_process(delta: float) -> void:
	# Update debug line
	var mesh = ImmediateMesh.new()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(ray.to_local(ray.to_global(ray.target_position)))
	mesh.surface_end()
	debug_line.mesh = mesh

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle Line of Sight to Player
	var player = get_player_in_sight()
	if player and is_in_sight(player):
		scanning = false
		# Make the enemy face the player
		var direction_to_player = (player.global_transform.origin - global_transform.origin).normalized()
		look_at(global_transform.origin + direction_to_player, Vector3.UP)
		
		# Move towards player
		velocity.x = direction_to_player.x * SPEED
		velocity.z = direction_to_player.z * SPEED
	else:
		if not scanning:
			# Reset scanning
			scanning = true
			scan_angle = rad_to_deg(ray.rotation.y)
			
		scan_angle += scan_speed * scan_direction * delta
		if scan_angle > scan_max:
			scan_angle = scan_max 
			scan_direction *= -1
		elif scan_angle < scan_min:
			scan_angle = scan_min
			scan_direction *= -1

		ray.rotation.y = deg_to_rad(scan_angle)

		# Stop moving when not tracking player
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	attack_timer -= delta

	move_and_slide()
	
	# Handle collision damage
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider() is CharacterBody3D and collision.get_collider().name == "Player" and attack_timer <= 0.0:
			collision.get_collider().take_damage(deal_damage())
			attack_timer = attack_cooldown

func get_player_in_sight() -> CharacterBody3D:
	for body in vision_area.get_overlapping_bodies():
		if body.name == "Player":
			return body
	return null

func is_in_sight(player: CharacterBody3D) -> bool:
	var to_player = player.global_transform.origin - global_transform.origin
	if to_player.length() > SIGHT_RANGE:
		return false
	
	# Field of view check
	var forward_dir = -global_transform.basis.z
	var angle_to_player = rad_to_deg(forward_dir.angle_to(to_player.normalized()))
	if angle_to_player > (VIEW_ANGLE / 2.0):
		return false

	ray.target_position = to_local(player.global_transform.origin)
	ray.force_raycast_update()
	return ray.is_colliding() and ray.get_collider() == player

func take_damage(amount: int) -> void:
	print("Enemy took ", amount, " damage!")
	health -= amount
	if health <= 0:
		die()

func deal_damage() -> int:
	return damage

func die() -> void:
	queue_free()
