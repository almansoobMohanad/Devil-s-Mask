extends CharacterBody3D

const SPEED := 8.0
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

# Patrol parameters
var is_chasing_player : bool = false
var returning_to_path_speed : float = SPEED / 1.5

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
		is_chasing_player = true
		scanning = false
		# Make the enemy face the player
		var direction_to_player = (player.global_transform.origin - global_transform.origin).normalized()
		look_at(global_transform.origin + direction_to_player, Vector3.UP)
		
		# Move towards player
		velocity.x = direction_to_player.x * SPEED
		velocity.z = direction_to_player.z * SPEED

		# Play move animation if not attacking
		if not is_attacking and anim_player.current_animation != "move":
			anim_player.play("move")

	else:
		# Normal patrol behavior - use velocity instead of teleporting
		path_follow.progress += patrol_speed * delta * path_direction
		
		# Get target position from path
		var target_pos = path_follow.global_transform.origin
		var direction_to_target = (target_pos - global_transform.origin)
		direction_to_target.y = 0
		direction_to_target = direction_to_target.normalized()
		
		# Move with velocity toward the path position
		velocity.x = direction_to_target.x * patrol_speed
		velocity.z = direction_to_target.z * patrol_speed
		
		# Look in movement direction
		if direction_to_target.length() > 0.01:
			look_at(global_transform.origin + direction_to_target, Vector3.UP)

		# Play move animation if not attacking
		if not is_attacking and anim_player.current_animation != "move":
			anim_player.play("move")
	
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

func take_damage(amount: int) -> int:
	print("Enemy took ", amount, " damage!")
	health -= amount
	if health <= 0:
		die()

	return amount

func deal_damage() -> int:
	return damage

func die() -> void:
	queue_free()
