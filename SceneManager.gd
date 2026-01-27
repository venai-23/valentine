extends Node

var fade_rect: ColorRect

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.modulate.a = 0.0
	layer.add_child(fade_rect)

func fade_out(duration := 0.35) -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await t.finished

func fade_in(duration := 0.35) -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await t.finished

func change_scene_faded(path: String, duration := 0.35) -> void:
	await fade_out(duration)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_in(duration)
