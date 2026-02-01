extends Node2D

enum State {
	IDLE,           # Walking around
	NEAR_VENAI,     # In range, prompt visible
	SHOWING_LETTER, # Letter sprite shown
	POPUP_OPEN,     # Valentine panel visible, movement disabled
	CELEBRATING,    # Hearts spawning, transitioning
}

# Node References
@onready var player := $Player
@onready var venai_zone := $Venai
@onready var venai_sprite := $Venai/VenaiSprite
@onready var letter_sprite := $LetterSprite
@onready var prompt_label := $UI/PromptLabel
@onready var valentine_panel := $UI/ValentinePanel
@onready var yes_button := $UI/ValentinePanel/YesButton
@onready var no_button := $UI/ValentinePanel/NoButton
@onready var heart_container := $HeartParticles

# Textures for hearts
@onready var heart_texture := preload("res://lastlevel_assets/heart_icons.png")

# State
var current_state := State.IDLE

# Venai sprite constants
const VENAI_FRAME_WIDTH := 341
const VENAI_FRAME_HEIGHT := 384


func _ready() -> void:
	# Connect signals
	venai_zone.body_entered.connect(_on_venai_entered)
	venai_zone.body_exited.connect(_on_venai_exited)
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)

	# Initialize visuals
	letter_sprite.visible = false
	valentine_panel.visible = false
	prompt_label.visible = false

	# Set Venai to first frame (static)
	venai_sprite.region_rect = Rect2(0, 0, VENAI_FRAME_WIDTH, VENAI_FRAME_HEIGHT)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		match current_state:
			State.NEAR_VENAI:
				_show_letter()
			State.SHOWING_LETTER:
				_open_popup()


func _on_venai_entered(body: Node) -> void:
	if body.is_in_group("player") and current_state == State.IDLE:
		current_state = State.NEAR_VENAI
		_show_prompt("Press E to talk to Venai")


func _on_venai_exited(body: Node) -> void:
	if body.is_in_group("player"):
		if current_state == State.NEAR_VENAI:
			current_state = State.IDLE
			_hide_prompt()
		elif current_state == State.SHOWING_LETTER:
			# If they walk away during letter, reset
			current_state = State.IDLE
			letter_sprite.visible = false
			_hide_prompt()


func _show_letter() -> void:
	current_state = State.SHOWING_LETTER
	letter_sprite.visible = true

	# Animate letter appearing
	letter_sprite.modulate.a = 0.0
	letter_sprite.scale = Vector2(0.1, 0.1)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(letter_sprite, "modulate:a", 1.0, 0.4)
	tween.tween_property(letter_sprite, "scale", Vector2(0.25, 0.25), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_show_prompt("Press E to read the letter")


func _open_popup() -> void:
	current_state = State.POPUP_OPEN
	player.can_move = false
	letter_sprite.visible = false
	_hide_prompt()

	# Show valentine panel with animation
	valentine_panel.visible = true
	valentine_panel.modulate.a = 0.0
	valentine_panel.scale = Vector2(0.8, 0.8)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(valentine_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(valentine_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_yes_pressed() -> void:
	if current_state != State.POPUP_OPEN:
		return

	current_state = State.CELEBRATING
	valentine_panel.visible = false

	# Start infinite heart celebration
	_spawn_hearts()


func _on_no_pressed() -> void:
	if current_state != State.POPUP_OPEN:
		return

	# Restart level
	valentine_panel.visible = false
	player.can_move = true

	await get_tree().create_timer(0.3).timeout
	SceneManager.change_scene_faded("res://ValentineLevel.tscn")


func _spawn_hearts() -> void:
	# Spawn hearts infinitely
	while true:
		var heart = Sprite2D.new()
		heart.texture = heart_texture
		heart.region_enabled = true
		heart.region_rect = _random_heart_region()

		# Random position across screen
		heart.position = Vector2(
			randf_range(100, 1436),
			randf_range(800, 1024)
		)
		heart.scale = Vector2(0.15, 0.15)
		heart.modulate.a = 0.0
		heart.z_index = 10

		heart_container.add_child(heart)
		_animate_heart(heart, 0.0)

		# Wait before spawning next heart
		await get_tree().create_timer(0.08).timeout


func _random_heart_region() -> Rect2:
	# 3x3 grid, each heart ~512x341
	var col = randi() % 3
	var row = randi() % 3
	return Rect2(col * 512, row * 341, 512, 341)


func _animate_heart(heart: Sprite2D, delay: float) -> void:
	var tween = create_tween()
	tween.tween_interval(delay)

	# Fade in and float up with slight sway
	var target_y = heart.position.y - randf_range(400, 700)
	var sway_x = randf_range(-50, 50)

	tween.tween_property(heart, "modulate:a", 1.0, 0.3)
	tween.set_parallel(true)
	tween.tween_property(heart, "position:y", target_y, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "position:x", heart.position.x + sway_x, 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(heart, "rotation", randf_range(-0.3, 0.3), 2.0)
	tween.set_parallel(false)
	tween.tween_property(heart, "modulate:a", 0.0, 0.5)
	tween.tween_callback(heart.queue_free)


func _show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = true


func _hide_prompt() -> void:
	prompt_label.visible = false
