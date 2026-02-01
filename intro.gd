extends Node2D

@onready var player := $Player
@onready var dialogue_box: Panel = $UI/DialogueBox
@onready var dialogue_text: Label = $UI/DialogueBox/DialogueText
@onready var note_prompt := $Note/Prompt
@onready var exit_door: Area2D = get_node_or_null("../ExitDoor/Door Trigger")
@onready var door_blocker: StaticBody2D = get_node_or_null("../ExitDoor/DoorBlocker")

var near_note := false
var reading_note := false
var note_read := false

var note_lines := [
	"Tamara: A note from Venai...",
	"Note: \"Get through 3 levels from our dates to find me.\"",
	"Tamara: Alright, let's go."
]
var note_index := 0

func _ready() -> void:
	dialogue_box.visible = false
	note_prompt.visible = false
	if exit_door:
		exit_door.set_deferred("monitoring", false)  # Disable until note is read
		exit_door.body_entered.connect(_on_exit_entered)

func _input(event: InputEvent) -> void:
	
	# Start reading note
	if near_note and not reading_note and event.is_action_pressed("interact"):
		_start_note()
		return

	# Advance note dialogue
	if reading_note and event.is_action_pressed("ui_accept"):
		_next_note_line()

func _start_note() -> void:
	reading_note = true
	player.can_move = false
	note_prompt.visible = false

	dialogue_box.visible = true
	dialogue_box.z_index = 9999
	dialogue_box.modulate = Color(1,1,1,1)

	note_index = 0
	dialogue_text.text = note_lines[note_index]




func _next_note_line() -> void:
	note_index += 1
	if note_index >= note_lines.size():
		_end_note()
	else:
		dialogue_text.text = note_lines[note_index]

func _end_note() -> void:
	reading_note = false
	dialogue_box.visible = false
	player.can_move = true
	note_read = true
	if exit_door:
		exit_door.monitoring = true  # Enable exit trigger now that note is read
	if door_blocker:
		door_blocker.queue_free()  # Remove the physical barrier

func _on_note_body_entered(body: Node) -> void:
	if body == player:
		near_note = true
		if not reading_note:
			note_prompt.visible = true

func _on_note_body_exited(body: Node) -> void:
	if body == player:
		near_note = false
		note_prompt.visible = false

func _on_exit_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	player.can_move = false
	SceneManager.change_scene_faded("res://EscapeRoom.tscn")
