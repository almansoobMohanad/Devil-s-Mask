extends CharacterBody3D


const SPEED = 10.0
const JUMP_VELOCITY = 5
var health : int = 5
var damage : int = 1
var isMasked : bool = false
var mask_fragments: int = 0
var collected_fragments_ids: Array = []

@onready var maskTimer = $Timer

func _ready() -> void:
	pass
	#maskTimer.timeout.connect(Callable(self, "maskWorn").bind(1))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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

func maskWorn(maskLevel: int) -> void:
	isMasked = true
	if maskLevel > 0:
		maskTimer.start(maskLevel * 1)
	else:
		isMasked = false

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
