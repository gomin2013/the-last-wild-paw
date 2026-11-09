@tool
class_name ListeningStone
extends Area2D
## Easter egg (O-5): S1 EP.02, where Sera teaches the kittens to wait: "ให้นิ่ง ให้ฟัง". Standing
## still on this stone for hold_time reveals the line and a bonus. Optional: nothing in the stage
## needs it.

@export var hold_time := 2.0
@export var points := 500

var _held := 0.0
var _found := false
var _label: Label


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitorable = false
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(90, 40)
	shape.position = Vector2(0, -20)
	add_child(shape)
	_label = Label.new()
	_label.text = "ให้นิ่ง ให้ฟัง\nBe still. Listen."
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-140, -150)
	_label.size = Vector2(280, 80)
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color("f4ede1"))
	_label.add_theme_color_override("font_outline_color", Color("1f2433"))
	_label.add_theme_constant_override("outline_size", 8)
	_label.modulate.a = 0.0
	add_child(_label)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _found:
		return
	var still := false
	for body in get_overlapping_bodies():
		if body.has_method("is_still") and body.is_still():
			still = true
	_held = _held + delta if still else 0.0
	if _held >= hold_time:
		_found = true
		GameState.easter_egg = true
		GameState.add_bonus(points)
		GameState.play_sfx("pickup")
		create_tween().tween_property(_label, "modulate:a", 1.0, 0.8)


func _draw() -> void:
	draw_colored_polygon(
		[Vector2(-46, 0), Vector2(-38, -14), Vector2(30, -16), Vector2(46, 0)], Color("9a8c7a")
	)
	draw_line(Vector2(-36, -12), Vector2(28, -14), Color("b8ab98"), 3.0)
