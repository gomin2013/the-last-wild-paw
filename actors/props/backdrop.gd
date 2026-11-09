@tool
class_name Backdrop
extends Node2D
## One paper plane of the background, drawn across `width` so a Parallax2D can repeat it.
## FAR: lake and far hills. MID: low rocks and reeds by the water.

enum Layer { FAR, MID }

@export var plane := Layer.FAR:
	set(v):
		plane = v
		queue_redraw()
@export var width := 2560.0
@export var base_y := 440.0


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11 if plane == Layer.FAR else 23
	if plane == Layer.FAR:
		draw_rect(Rect2(0, base_y - 40, width, 400), Color("6f8e95"))
		draw_rect(Rect2(0, base_y - 40, width, 6), Color("8fb0b5"))
		_ridge(rng, base_y - 40, 60.0, 130.0, Color("b8a68a"))
		_ridge(rng, base_y - 40, 20.0, 70.0, Color("9a8c7a"))
	else:
		_ridge(rng, base_y + 70, 30.0, 90.0, Color("a88f6a"))
		var x := 0.0
		while x < width:
			x += rng.randf_range(30.0, 120.0)
			for i in rng.randi_range(3, 7):
				var h := rng.randf_range(60.0, 150.0)
				var lean := rng.randf_range(-14.0, 14.0)
				var bx := x + i * 6.0
				draw_line(
					Vector2(bx, base_y + 120),
					Vector2(bx + lean, base_y + 120 - h),
					Color("7d7f4a"),
					4.0
				)


func _ridge(rng: RandomNumberGenerator, y: float, low: float, high: float, color: Color) -> void:
	var pts: PackedVector2Array = [Vector2(0, y)]
	var x := 0.0
	while x < width:
		pts.append(Vector2(x, y - rng.randf_range(low, high)))
		x += rng.randf_range(90.0, 220.0)
	pts.append(Vector2(width, pts[1].y))  # same height at both ends so the plane tiles
	pts.append(Vector2(width, y))
	var shadow := pts.duplicate()
	for i in shadow.size():
		shadow[i] += Vector2(5, 4)
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.12))
	draw_colored_polygon(pts, color)
