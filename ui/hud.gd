extends Control
## In-stage HUD: hearts (top left), food, score and time (top right). Hearts come from Kai's signal
## via the stage.

var _hearts := 3
var _max_hearts := 3

@onready var _stats: Label = $Stats


func set_hearts(hearts: int, max_hearts: int) -> void:
	_hearts = hearts
	_max_hearts = max_hearts
	queue_redraw()


func _process(_delta: float) -> void:
	_stats.text = (
		"Food %d    Score %d    %s"
		% [GameState.food, GameState.score, GameState.format_time(GameState.time)]
	)


func _draw() -> void:
	for i in _max_hearts:
		var c := Vector2(40 + i * 46, 40)
		var col := Color("f2643d") if i < _hearts else Color(0.12, 0.14, 0.2, 0.55)
		draw_circle(c + Vector2(-8, -4), 11.0, col)
		draw_circle(c + Vector2(8, -4), 11.0, col)
		draw_colored_polygon([c + Vector2(-19, 0), c + Vector2(19, 0), c + Vector2(0, 20)], col)
