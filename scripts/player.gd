extends CharacterBody3D


const SPEED = 10.0
const JUMP_VELOCITY = 5
const MASK_MULTIPLIER = 1
var health : int = 5
var damage : int = 1
var maskLevel : int = 1
var isMasked : bool = false
var mask_fragments: int = 0
var collected_fragments_ids: Array = []
var isArmed : bool = false

@onready var maskTimer = $Timer

func _ready() -> void:
	pass
	#maskTimer.timeout.connect(Callable(self, "maskWorn").bind(1))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 7

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle Mask Wear
	if Input.is_action_just_pressed("mask_wear"):
		maskWorn()

	# Handle Attack
	if Input.is_action_just_pressed("attack") and isArmed:
		for enemy in get_parent().get_node("Enemies").get_children():
			if global_transform.origin.distance_to(enemy.global_transform.origin) < 3.0:
				enemy.take_damage(deal_damage())

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		game_over()

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
	emit_signal("Game Over")

	# Implement game over logic here (e.g., restart level, show game over screen, etc.)
	
	
func add_mask_fragment(id: int):
	mask_fragments += 1
	collected_fragments_ids.append(id)
	print("Fragment collected! Total: ", mask_fragments)
	update_player_power()

func update_player_power():
	# Add your power-up logic here
	pass
