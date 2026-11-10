@tool
class_name Offering
extends Den
## Stage 2's clear zone (S1 EP.11 "A Trust Not Given"): a flat stone at the camp's edge where the
## people left a fish and walked away. Kai reaches it once they have gone.

const FISH := preload("res://assets/props/fish.png")  # series fish-on-a-stone standee


func _draw() -> void:
	var size := Vector2(FISH.get_width(), FISH.get_height()) * 0.55
	draw_texture_rect(FISH, Rect2(Vector2(-size.x / 2.0, -size.y + 4.0), size), false)
