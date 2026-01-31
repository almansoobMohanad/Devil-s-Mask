extends Area3D

@export var fragment_id: int = 0
@onready var model = $MeshInstance3D  # Reference your existing model

func _ready():
	body_entered.connect(_on_body_entered)
	
	if model:  # Make sure model exists
		setup_animations()

func setup_animations():
	# Rotation animation
	var rotation_tween = create_tween().set_loops()
	rotation_tween.tween_property(model, "rotation:y", TAU, 3.0)
	
	# Float animation - use a separate tween
	var float_tween = create_tween().set_loops()
	float_tween.tween_property(model, "position:y", 0.2, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(model, "position:y", -0.2, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect(body)

func collect(player):
	if player.has_method("add_mask_fragment"):
		player.add_mask_fragment(fragment_id)
	queue_free()
