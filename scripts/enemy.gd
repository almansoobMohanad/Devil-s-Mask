extends CharacterBody3D

const SPEED := 10.0
const SIGHT_RANGE := 20.0
const VIEW_ANGLE := 100.0
@export var path_follow_path : NodePath
@onready var ray = $VisionRayCast
@onready var vision_area = $VisionArea
@onready var path_follow = get_node(path_follow_path)
@onready var debug_line = $DebugLine
@onready var anim_player = $demon/AnimationPlayer
@onready var model = $demon

var health : int = 3
var damage : int = 1
var attack_cooldown : float = 1.0
var attack_timer : float = 0.0
var patrol_speed : float = SPEED / 2
var path_direction : int = 1  # 1 for forward, -1 for backward
var is_attacking : bool = false

# Scanning parameters
var scan_speed : float = 1.0
var scan_angle : float = 0.0
var scanning : bool = true

# Scanning limits in radians
var scan_min : float = -4 
var scan_max : float = 4
var scan_direction : int = 1 # 1 for right, -1 for left

func _ready():
	# Connect animation finished signal
	if anim_player:
		anim_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Update debug line
	# Draw a triangle for the POV angle (centered on forward direction)
	var mesh = ImmediateMesh.new()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius = SIGHT_RANGE
	var half_angle = deg_to_rad(VIEW_ANGLE / 2.0)
	var forward = Vector3(0, 1, radius)
	var left = Vector3(radius * sin(-half_angle), 0, radius * cos(-half_angle))
	var right = Vector3(radius * sin(half_angle), 0, radius * cos(half_angle))
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(left)
	mesh.surface_add_vertex(right)
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
	elif not (player and is_in_sight(player)):
		path_follow.progress += patrol_speed * delta
		global_transform.origin = path_follow.global_transform.origin
		look_at(path_follow.global_transform.origin + path_follow.transform.basis.z, Vector3.UP)
	
		# Play move animation if not attacking
		if not is_attacking and anim_player.current_animation != "move":
			anim_player.play("move")
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
		
		# Stop move animation when idle
		if anim_player.current_animation == "move":
			anim_player.stop()
	
	attack_timer -= delta
	move_and_slide()
	
	# Handle collision damage
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider() is CharacterBody3D and collision.get_collider().name == "Player" and attack_timer <= 0.0:
			# Play attack animation
			is_attacking = true
			anim_player.play("attack")
			collision.get_collider().take_damage(deal_damage())
			attack_timer = attack_cooldown

func _on_animation_finished(anim_name: String):
	# When attack animation finishes, allow movement again
	if anim_name == "attack":
		is_attacking = false

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
