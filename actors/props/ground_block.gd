@tool
class_name GroundBlock
extends StaticBody2D
## Solid ground or rock from its top-left corner, drawn as torn paper. Builds its own collision box.

enum Kind { GROUND, ROCK }

const PALETTE := {
	Kind.GROUND: [Color("8a6a46"), Color("c9a36a"), Color("7d7f4a")],
	Kind.ROCK: [Color("6e6458"), Color("9a8c7a"), Color("4f4840")],
}

@export var size := Vector2(256, 160):
	set(v):
		size = v
		_build()
@export var kind := Kind.GROUND:
	set(v):
		kind = v
		queue_redraw()


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	var shape := get_node_or_null("Shape") as CollisionShape2D
	if not shape:
		shape = CollisionShape2D.new()
		shape.name = "Shape"
		shape.shape = RectangleShape2D.new()
		add_child(shape)
	(shape.shape as RectangleShape2D).size = size
	shape.position = size / 2.0
	queue_redraw()


func _draw() -> void:
	var c: Array = PALETTE[kind]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(position))
	# Torn top edge, a slightly offset darker sheet behind it for the paper-layer look
	var top: PackedVector2Array = []
	var x := 0.0
	while x < size.x:
		top.append(Vector2(x, rng.randf_range(-3.0, 3.0)))
		x += rng.randf_range(14.0, 30.0)
	top.append(Vector2(size.x, 0))
	var sheet := top.duplicate()
	sheet.append_array([Vector2(size.x, size.y), Vector2(0, size.y)])
	var shadow := sheet.duplicate()
	for i in shadow.size():
		shadow[i] += Vector2(4, 5)
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.18))
	draw_colored_polygon(sheet, c[0])
	var band := top.duplicate()
	for i in range(top.size() - 1, -1, -1):
		band.append(top[i] + Vector2(0, minf(18.0, size.y * 0.3)))
	draw_colored_polygon(band, c[1])
	if kind == Kind.GROUND:
		for i in int(size.x / 70.0):
			var gx := rng.randf_range(8.0, size.x - 8.0)
			for b in 3:
				draw_line(Vector2(gx, 2), Vector2(gx + (b - 1) * 6.0, -14.0 - b * 2.0), c[2], 3.0)
	else:
		for i in int(size.x / 60.0) + 1:
			var fx := rng.randf_range(10.0, size.x - 10.0)
			draw_line(Vector2(fx, 22), Vector2(fx + rng.randf_range(-12, 12), size.y), c[2], 2.0)
