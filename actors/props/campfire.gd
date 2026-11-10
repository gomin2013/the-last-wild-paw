@tool
class_name Campfire
extends Node2D
## Stage 2 backdrop (S1 EP.10 "The Ones Beyond the Fire"): signs of a small Fayum camp, reed huts,
## basket-lined grain pits and a hearth with smoke, the firelight on the scene. No people: they have
## gone in for the night. Origin is the ground line under the hearth. Art: the series set kit.

const HUT := preload("res://assets/props/hut.png")
const HUT_SIDE := preload("res://assets/props/hut_side.png")
const HEARTH := preload("res://assets/props/hearth.png")
const PIT := preload("res://assets/props/pit.png")
const BASKET := preload("res://assets/props/basket.png")
const SMOKE := preload("res://assets/props/smoke.png")

var _t := 0.0
var _light: PointLight2D


func _ready() -> void:
	_light = PointLight2D.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	_light.texture = tex
	_light.texture_scale = 5.0
	_light.color = Color("ffb062")
	_light.position = Vector2(0, -30)
	add_child(_light)


func _process(delta: float) -> void:
	_t += delta
	_light.energy = 1.1 + sin(_t * 9.0) * 0.08 + sin(_t * 23.0) * 0.05
	queue_redraw()


func _draw() -> void:
	_put(HUT, Vector2(-290, 0), 1.0)
	_put(HUT_SIDE, Vector2(250, 0), 0.9)
	_put(PIT, Vector2(-120, 4), 0.5)
	_put(BASKET, Vector2(140, 2), 0.42)
	# Smoke drifts up and sways; the flames breathe with the light
	var sway := sin(_t * 1.3) * 6.0
	_put(SMOKE, Vector2(4 + sway, -110), 0.6, Color(1, 1, 1, 0.55 + sin(_t * 2.0) * 0.1))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.0 + sin(_t * 11.0) * 0.04))
	_put(HEARTH, Vector2.ZERO, 0.6)
	draw_set_transform(Vector2.ZERO)


## Texture standing on `foot` (its bottom centre), scaled by `s`.
func _put(tex: Texture2D, foot: Vector2, s: float, tint := Color.WHITE) -> void:
	var size := Vector2(tex.get_width(), tex.get_height()) * s
	draw_texture_rect(tex, Rect2(foot - Vector2(size.x / 2.0, size.y), size), false, tint)
