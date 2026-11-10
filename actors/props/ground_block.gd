@tool
class_name GroundBlock
extends StaticBody2D
## Solid ground or rock from its top-left corner, in Paper Collage earth (assets/props/ground.png;
## rock is the same paper, greyer). Builds its own collision box.

enum Kind { GROUND, ROCK }

const GROUND := preload("res://assets/props/ground.png")
const DEEP := Color("5a3f2a")  # the strip's bottom earth colour, for blocks deeper than the strip
const TINT := {Kind.GROUND: Color.WHITE, Kind.ROCK: Color(0.78, 0.74, 0.72)}

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
	# Paper earth strip tiled along the top at half size; deeper earth below it
	var tint: Color = TINT[kind]
	var tile := Vector2(GROUND.get_width(), GROUND.get_height()) * 0.5
	draw_rect(Rect2(Vector2(4, 5), size), Color(0, 0, 0, 0.18))
	var h := minf(size.y, tile.y)
	var x := 0.0
	while x < size.x:
		var w := minf(tile.x, size.x - x)
		draw_texture_rect_region(GROUND, Rect2(x, 0, w, h), Rect2(0, 0, w * 2.0, h * 2.0), tint)
		x += tile.x
	if size.y > tile.y:
		draw_rect(Rect2(0, tile.y - 1.0, size.x, size.y - tile.y + 1.0), DEEP * tint)
