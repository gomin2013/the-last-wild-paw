@tool
class_name Thorns
extends Area2D
## Thorn scrub (FR-04): touching it costs a heart and sends Kai back to the respawn point.

@export var size := Vector2(160, 60):
	set(v):
		size = v
		_build()
@export var damage := 1
@export var respawn: Marker2D


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
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(position))
	var x := 0.0
	while x < size.x:
		var w := rng.randf_range(34.0, 56.0)
		var h := rng.randf_range(size.y * 0.6, size.y)
		var bush: PackedVector2Array = [Vector2(x, size.y)]
		for i in 7:
			var t := (i + 1) / 8.0
			var r := h if i % 2 == 0 else h * 0.55
			bush.append(Vector2(x + w * t, size.y - r * sin(t * PI)))
		bush.append(Vector2(x + w, size.y))
		draw_colored_polygon(bush, Color("4f4a2c") if int(x) % 2 == 0 else Color("5d5634"))
		for i in 4:
			var sx := x + rng.randf_range(4.0, w - 4.0)
			var sy := size.y - rng.randf_range(6.0, h * 0.8)
			draw_line(
				Vector2(sx, sy), Vector2(sx + rng.randf_range(-7, 7), sy - 9), Color("d9cba8"), 2.0
			)
		x += w * 0.8
