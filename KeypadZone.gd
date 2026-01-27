extends Area2D

signal interact_pressed

@onready var prompt: Label = $Prompt

var player_nearby := false

func _ready() -> void:
	prompt.visible = false

func _input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("interact"):
		emit_signal("interact_pressed")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		prompt.visible = false
