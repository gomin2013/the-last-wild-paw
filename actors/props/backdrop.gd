@tool
class_name Backdrop
extends Node2D
## One paper plane of the background, drawn across `width` so a Parallax2D can repeat it.
## FAR: far hills and the lake. MID: the bank with acacia / tamarisk and reed clumps.
## Art: assets/props (generated Paper Collage and the series S1 set kit).

enum Layer { FAR, MID }

const MOUNTAINS := preload("res://assets/props/mountains.png")
const LAKE := preload("res://assets/props/lake.png")
const WATER := Color("6f8ea0")
const TREES: Array[Texture2D] = [
	preload("res://assets/props/acacia.png"), preload("res://assets/props/tamarisk.png")
]
const CLUMPS: Array[Texture2D] = [
	preload("res://assets/props/reed_tall.png"),
	preload("res://assets/props/reed_low.png"),
	preload("res://assets/props/grass_tall.png"),
	preload("res://assets/props/tussock.png"),
	preload("res://assets/props/shrub.png"),
]

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
		_strip(MOUNTAINS, base_y - 20)
		var lake_top := base_y - 70
		draw_rect(Rect2(0, lake_top + LAKE.get_height() - 8, width, 400), WATER)
		_strip(LAKE, lake_top + LAKE.get_height())
		return
	_ridge(rng, base_y + 140, 8.0, 24.0, Color("9a7f58"))  # a low bank, the lake stays visible
	# Trees stand back on the bank; reed and grass clumps in front of them
	var x := rng.randf_range(80.0, 300.0)
	while x < width - 200.0:
		var tree: Texture2D = TREES[rng.randi() % TREES.size()]
		_cutout(tree, x, base_y + 132, rng.randf_range(0.42, 0.55))
		x += rng.randf_range(500.0, 900.0)
	x = 0.0
	while x < width:
		var clump: Texture2D = CLUMPS[rng.randi() % CLUMPS.size()]
		_cutout(clump, x, base_y + 140, rng.randf_range(0.35, 0.55))
		x += rng.randf_range(60.0, 170.0)


## One texture repeated across the plane, every other copy mirrored so the joins always match.
func _strip(tex: Texture2D, bottom: float) -> void:
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	var i := 0
	while i * w < width:
		# A negative rect size draws nothing, so mirror with the canvas transform instead
		var flip := i % 2 == 1
		draw_set_transform(
			Vector2(i * w + (w if flip else 0.0), 0), 0, Vector2(-1 if flip else 1, 1)
		)
		draw_texture_rect(tex, Rect2(0, bottom - h, w, h), false)
		i += 1
	draw_set_transform(Vector2.ZERO)


func _cutout(tex: Texture2D, x: float, bottom: float, s: float) -> void:
	var size := Vector2(tex.get_width(), tex.get_height()) * s
	draw_texture_rect(tex, Rect2(Vector2(x - size.x / 2.0, bottom - size.y), size), false)


func _ridge(rng: RandomNumberGenerator, y: float, low: float, high: float, color: Color) -> void:
	var pts: PackedVector2Array = [Vector2(0, y)]
	var x := 0.0
	while x < width:
		pts.append(Vector2(x, y - rng.randf_range(low, high)))
		x += rng.randf_range(90.0, 220.0)
	pts.append(Vector2(width, pts[1].y))  # same height at both ends so the plane tiles
	pts.append(Vector2(width, y))
	draw_colored_polygon(pts, color)
