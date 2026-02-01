extends Area3D

@export var next_scene: String = ""  # Type the path manually like: "res://scenes/level2.tscn"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if next_scene != "":
			get_tree().change_scene_to_file(next_scene)
		else:
			print("No scene set for this door!")
