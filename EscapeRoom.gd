extends Node2D

@onready var player := $Player
@onready var keypad_zone := $KeypadZone
@onready var keypad_ui := $UI/KeypadUI
@onready var exit_door := $ExitDoor

var using_keypad := false
var keypad_solved := false

func _ready() -> void:
	keypad_zone.interact_pressed.connect(_on_keypad_interact)
	keypad_ui.code_correct.connect(_on_code_correct)
	exit_door.body_entered.connect(_on_exit_door_entered)

func _input(event: InputEvent) -> void:
	if using_keypad and event.is_action_pressed("ui_cancel"):
		_close_keypad()

func _on_keypad_interact() -> void:
	if using_keypad:
		return
	using_keypad = true
	player.can_move = false
	keypad_ui.open()

func _close_keypad() -> void:
	using_keypad = false
	player.can_move = true
	keypad_ui.close()

func _on_code_correct() -> void:
	using_keypad = false
	player.can_move = true
	keypad_solved = true
	print("Keypad unlocked! Exit door is now open.")

func _on_exit_door_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if keypad_solved:
		# Change to your next scene
		SceneManager.change_scene_faded("res://ConcertLevel.tscn")
	else:
		print("The door is locked. Enter the code on the keypad.")
