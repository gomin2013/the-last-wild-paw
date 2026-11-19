@tool
class_name Checkpoint
extends Area2D
## Mid-stage checkpoint: a cairn of stones (S1 set-kit rock). Kai passing it saves the spot and the
## run so far in GameState; after a game over, "Try again" starts here with that score and time.

const STONE := preload("res://assets/props/rock_small.png")  # series S1 set kit

var _lit := false


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitorable = false
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(60, 400)
	shape.position = Vector2(0, -200)
	add_child(shape)
	_lit = GameState.checkpoint_x() >= global_position.x
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _lit or not body is Kai or not GameState.running:
		return
	_lit = true
	GameState.set_checkpoint(global_position)
	GameState.play_sfx("pickup")
	scale = Vector2(1.25, 0.8)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	queue_redraw()


func _draw() -> void:
	# Three stones, smallest on top; grey until Kai reaches it
	var tint := Color.WHITE if _lit else Color(0.78, 0.76, 0.74)
	var y := 4.0
	for s: float in [0.5, 0.38, 0.27]:
		var size := Vector2(STONE.get_width(), STONE.get_height()) * s
		draw_texture_rect(STONE, Rect2(Vector2(-size.x / 2.0, y - size.y), size), false, tint)
		y -= size.y * 0.8
	if _lit:
		draw_circle(Vector2(0, y - 8), 7.0, UiKit.CORAL)
