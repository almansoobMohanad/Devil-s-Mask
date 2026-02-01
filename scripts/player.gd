extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 20
const MASK_MULTIPLIER = 1
const ATTACK_DISTANCE = 10 
const FRAGMENT_TIME : float = 2.0  # Seconds per fragment
const MASK_COOLDOWN_TIME : float = 1.0  # Cooldown time after transforming

var health : int = 5
var damage : int = 1
var maskLevel : int = 1
var mask_fragments: int = 0
var collected_fragments_ids: Array = []
var isArmed : bool = true # change to false if you want unarmed player at start
var is_jumping : bool = false  # Track if we're jumping
var is_transforming : bool = false  # Track if we're transforming

# World transformation system
var is_world_transformed : bool = false
var transform_timer : float = 0.0
var can_world_transform : bool = true
var mask_cooldown_timer : float = 0.0

# World references - Drag and drop in the inspector
@export var main_world : Node3D
@export var masked_world : Node3D
@export var unmasked_world : Node3D

@onready var anim_player = $Man/AnimationPlayer
@onready var model = $Man  # Reference to the visual model
@onready var mask_node = $Man/mask  # Reference to the mask container

@onready var sfx_jump: AudioStreamPlayer3D = $sfx_jump
@onready var sfx_game_over: AudioStreamPlayer3D = $sfx_game_over
@onready var sfx_masknextlevel: AudioStreamPlayer3D = $sfx_masknextlevel
@onready var sfx_update_power: AudioStreamPlayer3D = $sfx_update_power
@onready var sfx_take_damage: AudioStreamPlayer3D = $sfx_take_damage

func _ready() -> void:
	# Connect to animation finished signal
	anim_player.animation_finished.connect(_on_animation_finished)
	
	# Add to player group if not already
	if not is_in_group("player"):
		add_to_group("player")
	
	# Initialize mask visibility
	update_mask_visibility()
	
	# Initialize worlds
	update_world_visibility()

func _physics_process(delta: float) -> void:
	# Handle world transform timer
	if is_world_transformed:
		transform_timer -= delta
		if transform_timer <= 0.0:
			# Time's up, revert to unmasked world
			revert_world_transform()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 5
	else:
		# Just landed
		is_jumping = false
		
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true  # Mark that we're jumping
		#anim_player.play("Global/metarig_walking")  # Play jump animation immediately
		sfx_jump.play()
	
	# Handle Transform (E key) - Now toggles world transformation
	if mask_cooldown_timer > 0.0:
		mask_cooldown_timer -= delta
		print("Cooldown timer: ", mask_cooldown_timer)
		if mask_cooldown_timer <= 0.0:
			print("World transformation is ready again!")
			can_world_transform = true
	
	if Input.is_action_just_pressed("transform") and not is_transforming and can_world_transform:
		is_transforming = true
		anim_player.play("Global/metarigAction", -1, 4)
		toggle_world_transform()

		
	# Handle Attack (if armed)
	if Input.is_action_just_pressed("attack") and isArmed:
		anim_player.play("Global/metarigAction_fighting", -1, 4)
		var enemies_node = get_parent().get_node_or_null("Enemies") # Assuming all enemies are children of a node named "Enemies"
		
		if enemies_node: 
			for enemy in enemies_node.get_children():
				if enemy is CharacterBody3D:
					attack(enemy)
		else:
			var enemy = get_parent().get_node_or_null("Enemy")
			if enemy and enemy is CharacterBody3D:
				attack(enemy)
				
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# ROTATE ONLY THE MODEL (not the whole player)
		rotate_model(direction, delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	move_and_slide()
	
	# Update animations - only if not jumping, fighting, or transforming
	if not is_jumping and not is_transforming:
		update_animation(direction)

	if position.y < 0:
		get_tree().change_scene_to_file("res://scenes/gameover.tscn")
	
func _on_animation_finished(anim_name: String):
	# When transform animation finishes, allow other animations
	if anim_name == "Global/metarigAction":
		is_transforming = false
		update_mask_visibility()

func rotate_model(direction: Vector3, delta: float):
	# Get the angle to face based on movement direction
	var target_angle = atan2(-direction.x, -direction.z) - PI/2
	
	# Smoothly rotate ONLY the model (Man node), not the player
	var rotation_speed = 10.0  # Adjust this for faster/slower turning
	model.rotation.y = lerp_angle(model.rotation.y, target_angle, rotation_speed * delta)

func update_animation(direction: Vector3):
	# Don't change animation if fighting is playing
	if anim_player.current_animation == "Global/metarigAction_fighting" and anim_player.is_playing():
		return
	
	# Simple: Moving = run, Standing = breathing
	if direction.length() > 0:
		# Moving - running
		if anim_player.current_animation != "Global/metarigAction_run":
			anim_player.play("Global/metarigAction_run", -1, 5)
	else:
		# Standing still - breathing (idle)
		if anim_player.current_animation != "Global/metarigAction_breathing":
			anim_player.play("Global/metarigAction_breathing")

func take_damage(amount: int) -> void:
	print("Player took ", amount, " damage!")
	health -= amount
	sfx_take_damage.play()
	if health <= 0:
		game_over()

func increase_health(amount: int) -> void:
	health += amount
	print("Player health increased to ", health)

func attack(enemy: CharacterBody3D) -> void:
	print("Checking enemy: ", enemy.name)
	if global_transform.origin.distance_to(enemy.global_transform.origin) < ATTACK_DISTANCE:
		print("Attacking enemy: ", enemy.name)
		enemy.take_damage(deal_damage())
		increase_health(deal_damage())  # Heal player on successful attack

func deal_damage() -> int:
	return damage

func maskNextLevel() -> void:
	maskLevel += 1
	sfx_masknextlevel.play()

func armPlayer() -> void:
	isArmed = true

func _process(delta):
	if position.y < 0: # adjust threshold
		game_over()  # call your game over function directly

func game_over() -> void:
	print("Game Over!")
	emit_signal("Game Over")
	sfx_game_over.play()
	# Implement game over logic here (e.g., restart level, show game over screen, etc.)

# World Transformation Functions
func toggle_world_transform() -> void:
	if mask_fragments <= 0:
		print("No mask fragments available! Cannot transform worlds.")
		return

	if is_world_transformed:
		# Player wants to cancel transformation early
		revert_world_transform()
	else:
		# Transform to masked world
		is_world_transformed = true
		transform_timer = mask_fragments * FRAGMENT_TIME
		update_world_visibility()
		update_mask_visibility()
		print("World transformed! Time remaining: ", transform_timer, " seconds")
		# Start cooldown
		can_world_transform = false
		mask_cooldown_timer = MASK_COOLDOWN_TIME

func revert_world_transform() -> void:
	is_world_transformed = false
	transform_timer = 0.0
	update_world_visibility()
	update_mask_visibility()
	print("Reverted to normal world")
	# Start cooldown if not already running
	if mask_cooldown_timer <= 0.0:
		can_world_transform = false
		mask_cooldown_timer = MASK_COOLDOWN_TIME

func update_world_visibility() -> void:
	if main_world:
		main_world.visible = true  # Always visible
		set_world_process_mode(main_world, true)
	
	if masked_world:
		masked_world.visible = is_world_transformed
		set_world_process_mode(masked_world, is_world_transformed)
	
	if unmasked_world:
		unmasked_world.visible = not is_world_transformed
		set_world_process_mode(unmasked_world, not is_world_transformed)

func set_world_process_mode(world: Node3D, enabled: bool) -> void:
	if not world:
		return
	
	# Set the process mode to disable physics and processing when not visible
	if enabled:
		world.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		world.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Recursively disable all collisions in the world
	disable_collisions_recursive(world, not enabled)

func disable_collisions_recursive(node: Node, disable: bool) -> void:
	# Disable collision shapes FIRST - this is the key part
	if node is CollisionShape3D or node is CollisionPolygon3D:
		node.disabled = disable
	
	# Handle CSG objects (they have their own collision system)
	if node is CSGShape3D:
		if disable:
			# Store original use_collision state
			if not node.has_meta("original_use_collision"):
				node.set_meta("original_use_collision", node.use_collision)
			node.use_collision = false
		else:
			# Restore original use_collision state
			if node.has_meta("original_use_collision"):
				node.use_collision = node.get_meta("original_use_collision")
	
	# Disable Area3D and physics bodies
	if node is Area3D or node is StaticBody3D or node is RigidBody3D or node is CharacterBody3D:
		if disable:
			# Store original collision layer/mask
			if not node.has_meta("original_collision_layer"):
				node.set_meta("original_collision_layer", node.collision_layer)
				node.set_meta("original_collision_mask", node.collision_mask)
			node.collision_layer = 0
			node.collision_mask = 0
		else:
			# Restore original collision layer/mask
			if node.has_meta("original_collision_layer"):
				node.collision_layer = node.get_meta("original_collision_layer")
				node.collision_mask = node.get_meta("original_collision_mask")
		
		# CRITICAL FIX: Also disable child collision shapes
		for child in node.get_children():
			if child is CollisionShape3D or child is CollisionPolygon3D:
				child.disabled = disable
	
	# Recursively process all children
	for child in node.get_children():
		disable_collisions_recursive(child, disable)

func add_mask_fragment(id: int):
	mask_fragments += 1
	collected_fragments_ids.append(id)
	print("Fragment collected! Total: ", mask_fragments, " (", mask_fragments * FRAGMENT_TIME, " seconds available)")
	update_mask_visibility()
	update_player_power()

func update_player_power():
	sfx_update_power.play()
	pass

func update_mask_visibility():
	if not mask_node:
		return
	
	# Hide all masks first
	for i in range(1, 6):
		var mask_piece = mask_node.get_node_or_null("mask_" + str(i))
		if mask_piece and mask_piece is MeshInstance3D:
			mask_piece.visible = false
	
	# Only show masks while transformed and after the transform animation ends
	if not is_world_transformed or is_transforming:
		return

	# Show masks based on fragment count (1 fragment = mask_1, 2 = mask_2, etc.)
	for i in range(1, min(mask_fragments + 1, 6)):
		var mask_piece = mask_node.get_node_or_null("mask_" + str(i))
		if mask_piece and mask_piece is MeshInstance3D:
			mask_piece.visible = true

func get_remaining_transform_time() -> float:
	return transform_timer

func get_fragment_count() -> int:
	return mask_fragments
