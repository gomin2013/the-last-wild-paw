@tool
class_name Thorns
extends Area2D
## Thorn scrub (FR-04): touching it costs a heart and sends Kai back to the respawn point.
## With `water` set it is deep lake water instead (Stage 2), same rule.

const SCRUB := preload("res://assets/props/thorns.png")

@export var size := Vector2(160, 60):
	set(v):
		size = v
		_build()
@export var damage := 1
@export var respawn: Marker2D
@export var water := false:
	set(v):
		water = v
		queue_redraw()


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitorable = false
	_build()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for body in get_overlapping_bodies():
		if body.has_method("hit_hazard"):
			body.hit_hazard(damage, respawn.global_position)


func _build() -> void:
	if not is_inside_tree():
		return
	var shape := get_node_or_null("Shape") as CollisionShape2D
	if not shape:
		shape = CollisionShape2D.new()
		shape.name = "Shape"
		shape.shape = RectangleShape2D.new()
		add_child(shape)
	(shape.shape as RectangleShape2D).size = size - Vector2(8, 14)
	shape.position = size / 2.0 + Vector2(0, 7)
	queue_redraw()


func _draw() -> void:
	if water:
		_draw_water()
		return
	# The scrub stands a little taller than its hit box so the thorns read before Kai touches them
	var h := size.y * 1.4
	var w := h * SCRUB.get_width() / SCRUB.get_height()
	var x := 0.0
	var i := 0
	while x < size.x:
		var part := minf(w, size.x - x)
		var src := Rect2(0, 0, part / w * SCRUB.get_width(), SCRUB.get_height())
		# Every other bush mirrored, via the canvas transform (a negative rect size draws nothing)
		var flip := i % 2 == 1
		draw_set_transform(
			Vector2(x + (part if flip else 0.0), 0), 0, Vector2(-1 if flip else 1, 1)
		)
		draw_texture_rect_region(SCRUB, Rect2(0, size.y - h, part, h), src)
		x += w * 0.8
		i += 1
	draw_set_transform(Vector2.ZERO)


func _draw_water() -> void:
	# Dark water down past the screen edge, light ripple lines on top
	draw_rect(Rect2(0, 8, size.x, 400), Color("2f4a5c"))
	draw_rect(Rect2(0, 8, size.x, 6), Color("8fb0bf"))
	var x := 14.0
	while x < size.x - 30.0:
		draw_line(
			Vector2(x, 28 + fmod(x, 3) * 9),
			Vector2(x + 26, 28 + fmod(x, 3) * 9),
			Color("6f8ea0"),
			2
		)
		x += 46.0
