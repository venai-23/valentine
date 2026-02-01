extends Node2D

# Game States
enum GameState {
	IDLE,
	# Dough Making
	MIXING_DOUGH,
	DOUGH_READY,
	# Butter
	ADDING_BUTTER,
	BUTTER_DONE,
	# Filling
	COOKING_FILLING,
	FILLING_READY,
	# Assembly
	ASSEMBLING,
	TART_ASSEMBLED,
	# Baking
	BAKING,
	# Done
	COMPLETE
}

enum AssemblyStep { NONE, ROLLED, FILLED, SEALED }

# Tunable Constants
const DOUGH_MIX_SPEED := 0.3
const DOUGH_PERFECT_MIN := 0.4
const DOUGH_PERFECT_MAX := 0.7

const BUTTER_FOLD_SPEED := 0.25
const BUTTER_DONE_THRESHOLD := 0.6
const BUTTER_RUINED_THRESHOLD := 0.9

const FILLING_COOK_SPEED := 0.15
const FILLING_OVERHEAT_SPEED := 0.1
const FILLING_DONE_THRESHOLD := 0.8

const BAKE_MIN_TIME := 5.0
const BAKE_MAX_TIME := 12.0

# Node References
@onready var player := $Player
@onready var prompt_label := $UI/PromptLabel
@onready var completion_panel := $UI/CompletionPanel
@onready var narrative_label := $UI/CompletionPanel/NarrativeLabel

# Station References
@onready var mixing_station := $Stations/MixingStation
@onready var bowl_sprite := $Stations/MixingStation/BowlSprite
@onready var dough_crumbly := $Stations/MixingStation/DoughCrumbly
@onready var dough_perfect := $Stations/MixingStation/DoughPerfect
@onready var dough_overworked := $Stations/MixingStation/DoughOverworked
@onready var butter_sprite := $Stations/MixingStation/ButterSprite

@onready var stove_station := $Stations/StoveStation
@onready var stove_off := $Stations/StoveStation/StoveOff
@onready var stove_on_sprite := $Stations/StoveStation/StoveOn
@onready var filling_watery := $Stations/StoveStation/FillingWatery
@onready var filling_bubbling := $Stations/StoveStation/FillingBubbling
@onready var filling_thick := $Stations/StoveStation/FillingThick

@onready var assembly_station := $Stations/AssemblyStation
@onready var assembly_sprite := $Stations/AssemblyStation/AssemblySprite

@onready var oven_station := $Stations/OvenStation
@onready var oven_sprite := $Stations/OvenStation/OvenSprite
@onready var tart_sprite := $Stations/OvenStation/TartSprite

# State Variables
var game_state := GameState.IDLE
var current_station: String = ""

# Dough variables
var dough_progress := 0.0
var dough_complete := false

# Butter variables
var butter_added := false
var butter_progress := 0.0
var butter_complete := false

# Filling variables
var stove_on := false
var filling_progress := 0.0
var filling_overheat := 0.0
var filling_complete := false

# Assembly variables
var assembly_step := AssemblyStep.NONE

# Baking variables
var baking := false
var bake_time := 0.0

# Feedback flash
var flash_tween: Tween


func _ready() -> void:
	# Connect station area signals
	mixing_station.body_entered.connect(_on_mixing_entered)
	mixing_station.body_exited.connect(_on_mixing_exited)

	stove_station.body_entered.connect(_on_stove_entered)
	stove_station.body_exited.connect(_on_stove_exited)

	assembly_station.body_entered.connect(_on_assembly_entered)
	assembly_station.body_exited.connect(_on_assembly_exited)

	oven_station.body_entered.connect(_on_oven_entered)
	oven_station.body_exited.connect(_on_oven_exited)

	# Initialize visuals
	_init_visuals()

	# Hide completion panel
	completion_panel.visible = false
	prompt_label.visible = false


func _init_visuals() -> void:
	# Bowl visible to show mixing station, dough hidden until mixing starts
	bowl_sprite.visible = true
	bowl_sprite.frame = 0  # Empty bowl
	dough_crumbly.visible = false
	dough_perfect.visible = false
	dough_overworked.visible = false
	butter_sprite.visible = false

	# Stove and filling hidden until cooking
	stove_off.visible = false
	stove_on_sprite.visible = false
	filling_watery.visible = false
	filling_bubbling.visible = false
	filling_thick.visible = false

	# Assembly hidden until ready
	assembly_sprite.visible = false
	assembly_sprite.frame = 0

	# Oven uses background, tart hidden until baking
	oven_sprite.visible = false
	tart_sprite.visible = false


func _process(delta: float) -> void:
	if game_state == GameState.COMPLETE:
		return

	# Process based on current station
	match current_station:
		"mixing":
			_process_mixing_station(delta)
		"stove":
			_process_stove_station(delta)
			# Stove and oven are same location - also check for oven interactions
			if baking or assembly_step == AssemblyStep.SEALED:
				_process_oven_station(delta)
		"assembly":
			_process_assembly_station(delta)
		"oven":
			_process_oven_station(delta)

	# Filling cooks passively when stove is on
	if stove_on and not filling_complete:
		_process_filling_cooking(delta)


func _process_mixing_station(delta: float) -> void:
	# Handle dough mixing
	if not dough_complete:
		if Input.is_action_pressed("interact"):
			dough_progress += delta * DOUGH_MIX_SPEED
			bowl_sprite.visible = true
			bowl_sprite.frame = 1  # Mixed bowl with spoon
			_update_dough_visual()

			# Check for overworking
			if dough_progress >= 1.0:
				_ruin_dough()

		_update_mixing_prompt()

	# Handle butter after dough is perfect
	elif dough_complete and not butter_complete:
		if not butter_added:
			if Input.is_action_just_pressed("interact"):
				butter_added = true
				butter_sprite.visible = true
				_show_prompt("Hold E to fold in butter")
		else:
			if Input.is_action_pressed("interact"):
				butter_progress += delta * BUTTER_FOLD_SPEED
				_update_butter_visual()

				if butter_progress >= BUTTER_RUINED_THRESHOLD:
					_ruin_dough()
				elif butter_progress >= BUTTER_DONE_THRESHOLD:
					butter_complete = true
					butter_sprite.visible = false
					# dough_perfect already visible from mixing
					_show_prompt("Dough ready! Go to assembly table")

		_update_butter_prompt()


func _update_dough_visual() -> void:
	# Hide all first
	dough_crumbly.visible = false
	dough_perfect.visible = false
	dough_overworked.visible = false

	# Show appropriate state
	if dough_progress < DOUGH_PERFECT_MIN:
		dough_crumbly.visible = true
	elif dough_progress < DOUGH_PERFECT_MAX:
		dough_perfect.visible = true
	else:
		dough_overworked.visible = true


func _update_butter_visual() -> void:
	# Fade butter into dough as progress increases
	var fade = 1.0 - (butter_progress / BUTTER_DONE_THRESHOLD)
	butter_sprite.modulate.a = clamp(fade, 0.0, 1.0)


func _update_mixing_prompt() -> void:
	if dough_progress < DOUGH_PERFECT_MIN:
		_show_prompt("Hold E to mix dough")
	elif dough_progress < DOUGH_PERFECT_MAX:
		if not dough_complete:
			_show_prompt("Release E - dough looks perfect!")
			# Check if player released
			if not Input.is_action_pressed("interact"):
				dough_complete = true
				_show_prompt("Press E to add butter")
	else:
		_show_prompt("Keep mixing... (careful!)")


func _update_butter_prompt() -> void:
	if not butter_added:
		_show_prompt("Press E to add butter")
	elif butter_progress < BUTTER_DONE_THRESHOLD:
		_show_prompt("Hold E to fold in butter")


func _ruin_dough() -> void:
	_flash_feedback(Color.RED)

	# Reset dough state
	dough_progress = 0.0
	dough_complete = false
	butter_added = false
	butter_progress = 0.0
	butter_sprite.visible = false
	butter_sprite.modulate.a = 1.0
	dough_crumbly.visible = false
	dough_perfect.visible = false
	dough_overworked.visible = false
	bowl_sprite.frame = 0  # Back to empty bowl
	bowl_sprite.visible = true  # Keep bowl visible

	_show_prompt("Dough ruined! Try again...")
	await get_tree().create_timer(1.5).timeout
	_show_prompt("Hold E to mix dough")


func _process_stove_station(_delta: float) -> void:
	# Don't process stove if we're baking or ready to bake (oven takes priority)
	if baking or assembly_step == AssemblyStep.SEALED:
		return

	if filling_complete:
		_hide_prompt()
		return

	if Input.is_action_just_pressed("interact"):
		if not stove_on:
			# Turn on stove
			stove_on = true
			stove_on_sprite.visible = true
			filling_watery.visible = true
			_show_prompt("Stove on - press E to stir")
		else:
			# Stir to prevent overheat
			filling_overheat = 0.0
			_show_prompt("Stirred! Keep an eye on it")


func _process_filling_cooking(delta: float) -> void:
	if not stove_on:
		return

	filling_progress += delta * FILLING_COOK_SPEED
	filling_overheat += delta * FILLING_OVERHEAT_SPEED

	_update_filling_visual()

	# Check if overheated (burnt)
	if filling_overheat > 1.0:
		_ruin_filling()
	elif filling_progress >= FILLING_DONE_THRESHOLD:
		filling_complete = true
		stove_on = false
		stove_on_sprite.visible = false
		# Show thick filling, hide others
		filling_watery.visible = false
		filling_bubbling.visible = false
		filling_thick.visible = true
		if current_station == "stove":
			_show_prompt("Filling perfect! Go to assembly table")


func _update_filling_visual() -> void:
	# Hide all first
	filling_watery.visible = false
	filling_bubbling.visible = false
	filling_thick.visible = false

	# Show appropriate state
	if filling_progress < 0.4:
		filling_watery.visible = true
	elif filling_progress < FILLING_DONE_THRESHOLD:
		filling_bubbling.visible = true
	else:
		filling_thick.visible = true


func _ruin_filling() -> void:
	_flash_feedback(Color.RED)

	# Reset filling - show burnt tint on current visible filling
	filling_progress = 0.0
	filling_overheat = 0.0
	var current_filling = _get_visible_filling()
	if current_filling:
		current_filling.modulate = Color(0.5, 0.3, 0.2)  # Burnt tint

	_show_prompt("Filling burnt! Resetting...")
	await get_tree().create_timer(1.5).timeout

	# Reset all filling sprites
	filling_watery.modulate = Color.WHITE
	filling_bubbling.modulate = Color.WHITE
	filling_thick.modulate = Color.WHITE
	filling_watery.visible = false
	filling_bubbling.visible = false
	filling_thick.visible = false
	stove_on = false
	stove_on_sprite.visible = false

	_show_prompt("Press E to start cooking filling")


func _get_visible_filling() -> Sprite2D:
	if filling_thick.visible:
		return filling_thick
	elif filling_bubbling.visible:
		return filling_bubbling
	elif filling_watery.visible:
		return filling_watery
	return null


func _process_assembly_station(_delta: float) -> void:
	# Check prerequisites
	var dough_ready = butter_complete
	var filling_ready = filling_complete

	if not dough_ready and not filling_ready:
		_show_prompt("Need dough and filling first!")
		return
	elif not dough_ready:
		_show_prompt("Need to prepare dough first!")
		return
	elif not filling_ready:
		_show_prompt("Need to cook filling first!")
		return

	# Assembly is ready
	if Input.is_action_just_pressed("interact"):
		match assembly_step:
			AssemblyStep.NONE:
				assembly_step = AssemblyStep.ROLLED
				assembly_sprite.visible = true
				assembly_sprite.frame = 0  # Flat dough
				_show_prompt("Press E to add filling")
			AssemblyStep.ROLLED:
				assembly_step = AssemblyStep.FILLED
				assembly_sprite.frame = 1  # With filling
				_show_prompt("Press E to fold and seal")
			AssemblyStep.FILLED:
				assembly_step = AssemblyStep.SEALED
				assembly_sprite.frame = 2  # Sealed tart
				game_state = GameState.TART_ASSEMBLED
				_show_prompt("Tart assembled! Take to oven")


func _process_oven_station(_delta: float) -> void:
	# Only process if tart is ready or baking
	if assembly_step != AssemblyStep.SEALED and not baking:
		return

	if Input.is_action_just_pressed("interact"):
		if not baking:
			_start_baking()
		else:
			_check_bake()


func _start_baking() -> void:
	baking = true
	bake_time = 0.0
	oven_sprite.visible = true
	oven_sprite.frame = 1  # Oven on/glowing
	tart_sprite.visible = true
	assembly_sprite.visible = false
	_show_prompt("Baking... press E to check")

	# Start bake timer in background
	_run_bake_timer()


func _run_bake_timer() -> void:
	while baking and game_state != GameState.COMPLETE:
		await get_tree().create_timer(0.1).timeout
		bake_time += 0.1


func _check_bake() -> void:
	if bake_time < BAKE_MIN_TIME:
		# Too early
		_show_prompt("Not ready yet...")
		_restore_baking_prompt()
	elif bake_time <= BAKE_MAX_TIME:
		# Perfect!
		_complete_level()
	else:
		# Burnt
		_burn_tart()


func _restore_baking_prompt() -> void:
	await get_tree().create_timer(1.0).timeout
	if baking and (current_station == "oven" or current_station == "stove"):
		_show_prompt("Baking... press E to check")


func _burn_tart() -> void:
	_flash_feedback(Color.RED)
	tart_sprite.modulate = Color(0.3, 0.2, 0.1)  # Burnt dark tint

	_show_prompt("Burnt! Let's try again...")
	await get_tree().create_timer(1.5).timeout

	# Reset to assembled state
	tart_sprite.visible = false
	tart_sprite.modulate = Color.WHITE
	oven_sprite.visible = false
	baking = false
	bake_time = 0.0
	assembly_sprite.visible = true

	_show_prompt("Press E to put tart in oven")


func _complete_level() -> void:
	game_state = GameState.COMPLETE
	baking = false
	player.can_move = false
	prompt_label.visible = false

	# Show golden tart
	tart_sprite.modulate = Color(1.1, 1.0, 0.9)  # Warm golden tint

	# Warm the kitchen lighting
	var tween = create_tween()
	tween.tween_property($Background, "modulate", Color(1.1, 1.0, 0.9), 1.0)

	await get_tree().create_timer(1.5).timeout

	# Show completion panel
	completion_panel.visible = true
	narrative_label.text = "Good job!"

	# Wait for player input
	await _wait_for_input()

	# Transition to next level
	SceneManager.change_scene_faded("res://ValentineLevel.tscn")


func _wait_for_input() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			break


func _flash_feedback(color: Color) -> void:
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()

	var target_sprite: Sprite2D
	match current_station:
		"mixing":
			# Flash whichever dough sprite is visible
			if dough_overworked.visible:
				target_sprite = dough_overworked
			elif dough_perfect.visible:
				target_sprite = dough_perfect
			elif dough_crumbly.visible:
				target_sprite = dough_crumbly
			else:
				return
		"stove":
			target_sprite = _get_visible_filling()
			if not target_sprite:
				return
		"oven":
			target_sprite = tart_sprite
		_:
			return

	flash_tween = create_tween()
	flash_tween.tween_property(target_sprite, "modulate", color, 0.1)
	flash_tween.tween_property(target_sprite, "modulate", Color.WHITE, 0.3)


func _show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = true


func _hide_prompt() -> void:
	prompt_label.visible = false


# Station enter/exit callbacks
func _on_mixing_entered(body: Node) -> void:
	if body.is_in_group("player"):
		current_station = "mixing"
		if not dough_complete:
			_show_prompt("Hold E to mix dough")
		elif not butter_complete:
			_show_prompt("Press E to add butter")
		else:
			_show_prompt("Dough ready! Go to assembly table")


func _on_mixing_exited(body: Node) -> void:
	if body.is_in_group("player") and current_station == "mixing":
		current_station = ""
		_hide_prompt()


func _on_stove_entered(body: Node) -> void:
	if body.is_in_group("player"):
		current_station = "stove"
		# Check oven state first (same location)
		if baking:
			_show_prompt("Baking... press E to check")
		elif assembly_step == AssemblyStep.SEALED:
			_show_prompt("Press E to put tart in oven")
		elif filling_complete:
			_hide_prompt()
		elif stove_on:
			_show_prompt("Press E to stir")
		else:
			_show_prompt("Press E to turn on stove")


func _on_stove_exited(body: Node) -> void:
	if body.is_in_group("player") and current_station == "stove":
		current_station = ""
		_hide_prompt()


func _on_assembly_entered(body: Node) -> void:
	if body.is_in_group("player"):
		current_station = "assembly"
		var dough_ready = butter_complete
		var filling_ready = filling_complete

		if not dough_ready and not filling_ready:
			_show_prompt("Need dough and filling first!")
		elif not dough_ready:
			_show_prompt("Need to prepare dough first!")
		elif not filling_ready:
			_show_prompt("Need to cook filling first!")
		elif assembly_step == AssemblyStep.SEALED:
			_show_prompt("Tart assembled! Take to oven")
		else:
			_show_prompt("Press E to roll out dough")


func _on_assembly_exited(body: Node) -> void:
	if body.is_in_group("player") and current_station == "assembly":
		current_station = ""
		_hide_prompt()


func _on_oven_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Only claim this as oven station if tart is ready or baking
		# Otherwise let the stove station handle it
		if baking or assembly_step == AssemblyStep.SEALED:
			current_station = "oven"
			if baking:
				_show_prompt("Baking... press E to check")
			else:
				_show_prompt("Press E to put tart in oven")


func _on_oven_exited(body: Node) -> void:
	if body.is_in_group("player") and current_station == "oven":
		current_station = ""
		_hide_prompt()
