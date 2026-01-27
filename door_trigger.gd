extends Area2D

@export_file("*.tscn") var target_scene: String
var triggered := false

func _on_body_entered(body: Node) -> void:
	if triggered:
		return
	if not (body is CharacterBody2D):
		return

	triggered = true

	# Freeze player if you use can_move
	if "can_move" in body:
		body.can_move = false

	await SceneManager.change_scene_faded(target_scene)
