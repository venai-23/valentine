extends Sprite2D

signal state_changed(new_state: int)

enum State { DANCING, TURNING, WATCHING }

@export var dance_time_min := 3.0
@export var dance_time_max := 6.0
@export var turn_time := 0.5
@export var watch_time_min := 2.0
@export var watch_time_max := 4.0

var current_state: State = State.DANCING
var state_timer := 0.0
var state_duration := 0.0

var dance_frames := [3, 4, 5]
var turn_frames := [6, 7, 8]
var watch_frames := [9, 10, 11]

var anim_timer := 0.0
var anim_speed := 0.2
var frame_idx := 0


func _ready() -> void:
	hframes = 3
	vframes = 4
	_enter_state(State.DANCING)


func _process(delta: float) -> void:
	state_timer += delta
	anim_timer += delta

	# Animate current state
	if anim_timer >= anim_speed:
		anim_timer = 0.0
		frame_idx = (frame_idx + 1) % 3
		_update_frame()

	# Check for state transition
	if state_timer >= state_duration:
		match current_state:
			State.DANCING:
				_enter_state(State.TURNING)
			State.TURNING:
				_enter_state(State.WATCHING)
			State.WATCHING:
				_enter_state(State.DANCING)


func _enter_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0
	frame_idx = 0
	anim_timer = 0.0

	match new_state:
		State.DANCING:
			state_duration = randf_range(dance_time_min, dance_time_max)
		State.TURNING:
			state_duration = turn_time
		State.WATCHING:
			state_duration = randf_range(watch_time_min, watch_time_max)

	_update_frame()
	state_changed.emit(new_state)


func _update_frame() -> void:
	match current_state:
		State.DANCING:
			frame = dance_frames[frame_idx]
		State.TURNING:
			frame = turn_frames[frame_idx]
		State.WATCHING:
			frame = watch_frames[frame_idx]


func is_watching() -> bool:
	return current_state == State.WATCHING
