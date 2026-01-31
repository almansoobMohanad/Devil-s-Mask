extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 20
const MASK_MULTIPLIER = 1
const ATTACK_DISTANCE = 10 

var health : int = 5
var damage : int = 1
var maskLevel : int = 1
var isMasked : bool = false
var mask_fragments: int = 0
var collected_fragments_ids: Array = []
var isArmed : bool = true
var is_jumping : bool = false  # Track if we're jumping
var is_transforming : bool = false  # Track if we're transforming

@onready var maskTimer = $Timer
@onready var anim_player = $Man/AnimationPlayer
@onready var model = $Man  # Reference to the visual model

func _ready() -> void:
	# Connect to animation finished signal
	anim_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
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
	
	# Handle Transform (E key)
	if Input.is_action_just_pressed("transform") and not is_transforming:
		is_transforming = true
		anim_player.play("Global/metarigAction")
		
	# Handle Mask Wear
	if Input.is_action_just_pressed("mask_wear"):
		maskWorn()
		
	# Handle Attack (if armed)
	if Input.is_action_just_pressed("attack") and isArmed:
		anim_player.play("Global/metarigAction_fighting")
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

func _on_animation_finished(anim_name: String):
	# When transform animation finishes, allow other animations
	if anim_name == "Global/metarigAction":
		is_transforming = false

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
	if health <= 0:
		game_over()

func attack(enemy: CharacterBody3D) -> void:
	print("Checking enemy: ", enemy.name)
	if global_transform.origin.distance_to(enemy.global_transform.origin) < ATTACK_DISTANCE:
		print("Attacking enemy: ", enemy.name)
		enemy.take_damage(deal_damage())

func deal_damage() -> int:
	return damage

func maskWorn() -> void:
	if isMasked:
		isMasked = false
		maskTimer.stop()
	else:
		isMasked = true
		maskTimer.start(maskLevel * MASK_MULTIPLIER)

func maskNextLevel() -> void:
	maskLevel += 1

func armPlayer() -> void:
	isArmed = true

func game_over() -> void:
	print("Game Over!")
	emit_signal("Game Over")

	# Implement game over logic here (e.g., restart level, show game over screen, etc.)
	
	
func add_mask_fragment(id: int):
	mask_fragments += 1
	collected_fragments_ids.append(id)
	print("Fragment collected! Total: ", mask_fragments)
	update_player_power()

func update_player_power():
	pass
