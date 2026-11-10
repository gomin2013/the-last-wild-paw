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
		var pts := _heart(c)
		if i < _hearts:
			draw_colored_polygon(pts, UiKit.CORAL)
		else:
			# One polygon, so the see-through fill has no darker overlaps
			draw_colored_polygon(pts, Color(UiKit.GRAPHITE, 0.45))
			pts.append(pts[0])
			draw_polyline(pts, Color(UiKit.CREAM, 0.7), 2.0, true)


## Heart outline (the classic sin³ curve) centred on c, about 40 px wide.
static func _heart(c: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 32:
		var t := TAU * k / 32.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y + 2.0) * 1.25)
	return pts
