extends Node2D

@onready var player := $Player
@onready var performer := $Performer
@onready var exit_zone := $ExitZone
@onready var music := $MusicPlayer
@onready var state_label := $UI/StateLabel
@onready var caught_overlay := $UI/CaughtOverlay

var player_start: Vector2
var is_resetting := false
var grace_timer := 0.0
const GRACE_PERIOD := 0.15


func _ready() -> void:
	player_start = player.position
	player.speed = 80.0  # Slower movement for this level
	performer.state_changed.connect(_on_state_changed)
	exit_zone.body_entered.connect(_on_exit_entered)
	caught_overlay.modulate.a = 0.0
	_on_state_changed(performer.current_state)


func _physics_process(delta: float) -> void:
	if is_resetting:
		return

	if performer.is_watching():
		grace_timer += delta
		if grace_timer > GRACE_PERIOD:
			if player.velocity.length() > 5.0:
				_player_caught()
	else:
		grace_timer = 0.0


func _on_state_changed(new_state: int) -> void:
	match new_state:
		performer.State.DANCING:
			state_label.text = "DANCE!"
			state_label.modulate = Color.GREEN
			if music:
				music.volume_db = 0.0
		performer.State.TURNING:
			state_label.text = "..."
			state_label.modulate = Color.YELLOW
		performer.State.WATCHING:
			state_label.text = "FREEZE!"
			state_label.modulate = Color.RED
			if music:
				music.volume_db = -10.0
	grace_timer = 0.0


func _player_caught() -> void:
	is_resetting = true

	# Flash red
	var tween := create_tween()
	tween.tween_property(caught_overlay, "modulate:a", 0.5, 0.1)
	tween.tween_property(caught_overlay, "modulate:a", 0.0, 0.3)
	await tween.finished

	_soft_reset()


func _soft_reset() -> void:
	player.position = player_start
	player.velocity = Vector2.ZERO
	is_resetting = false
	grace_timer = 0.0


func _on_exit_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if music:
			music.stop()
		SceneManager.change_scene_faded("res://NextLevel.tscn")
