@tool
class_name Den
extends Area2D
## The rocky den at the end of the stage: the clear zone (FR-06). Emits reached when Kai walks in.

signal reached

const ROCKS := preload("res://assets/props/den_rocks.png")


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
	# Series S1 set-kit den rocks, the cave mouth over the origin
	var size := Vector2(ROCKS.get_width(), ROCKS.get_height()) * 1.1
	draw_texture_rect(ROCKS, Rect2(Vector2(-size.x * 0.47, -size.y), size), false)
