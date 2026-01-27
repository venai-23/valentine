extends CharacterBody2D

@export var speed := 160.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var last_dir := Vector2.DOWN
var can_move := true

func _physics_process(_delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		last_dir = dir
		velocity = dir * speed
		_play_walk(dir)
	else:
		velocity = Vector2.ZERO
		anim.stop()

	move_and_slide()

func _play_walk(dir: Vector2) -> void:
	# default: no flip
	anim.flip_h = false

	# pick direction
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim.play("walk_left")   # reuse left frames
				  # flip to become right
		else:
			anim.play("walk_left")
			anim.flip_h = true
	else:
		if dir.y > 0:
			anim.play("walk_down")
		else:
			anim.play("walk_up")
