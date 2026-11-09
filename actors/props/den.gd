@tool
class_name Den
extends Area2D
## The rocky den at the end of the stage: the clear zone (FR-06). Emits reached when Kai walks in.

signal reached

const ROCK := Color("6e6458")
const ROCK_LIGHT := Color("9a8c7a")


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitorable = false
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(120, 140)
	shape.position = Vector2(0, -70)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Kai:
		reached.emit()


func _draw() -> void:
	draw_colored_polygon(
		[
			Vector2(-170, 0),
			Vector2(-140, -150),
			Vector2(-40, -230),
			Vector2(90, -210),
			Vector2(170, -90),
			Vector2(190, 0)
		],
		ROCK
	)
	draw_colored_polygon(
		[Vector2(-120, -140), Vector2(-40, -220), Vector2(60, -200), Vector2(-30, -150)], ROCK_LIGHT
	)
	draw_colored_polygon(
		[
			Vector2(-60, 0),
			Vector2(-56, -70),
			Vector2(-20, -110),
			Vector2(30, -104),
			Vector2(60, -60),
			Vector2(64, 0)
		],
		Color("2b2a2c")
	)
