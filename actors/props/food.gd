class_name Food
extends Area2D
## A bird egg in the scrub (FR-05): heals a heart when Kai is hurt, otherwise scores.

@export var points := 100

var _t := 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	(shape.shape as CircleShape2D).radius = 22.0
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_t = position.x


func _process(delta: float) -> void:
	_t += delta * 3.0
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("eat"):
		body.eat(points)
		queue_free()


func _draw() -> void:
	var y := sin(_t) * 3.0
	draw_set_transform(Vector2(0, y), 0.0, Vector2(0.78, 1.0))
	draw_circle(Vector2(3, 3), 14.0, Color(0, 0, 0, 0.2))
	draw_circle(Vector2.ZERO, 14.0, Color("f4ede1"))
	for s: Vector2 in [Vector2(-5, -4), Vector2(4, 2), Vector2(-2, 7), Vector2(6, -7)]:
		draw_circle(s, 1.8, Color("7a5a3c"))
