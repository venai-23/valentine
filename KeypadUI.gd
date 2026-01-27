extends Panel

signal code_correct

@export var correct_code := "1228"
@onready var code_label: Label = %CodeLabel

var typed := ""

func _ready() -> void:
	visible = false
	_update_label()

func open() -> void:
	typed = ""
	_update_label()
	visible = true

func close() -> void:
	visible = false

func press_digit(d: String) -> void:
	if typed.length() >= 4:
		return
	typed += d
	_update_label()

func clear() -> void:
	typed = ""
	_update_label()

func enter() -> void:
	if typed == correct_code:
		emit_signal("code_correct")
		close()
	else:
		code_label.text = "WRONG"
		typed = ""
		await get_tree().create_timer(0.35).timeout
		_update_label()

func _update_label() -> void:
	var s := typed
	while s.length() < 4:
		s += "_"
	code_label.text = s
