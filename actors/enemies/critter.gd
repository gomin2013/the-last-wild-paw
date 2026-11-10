class_name Critter
extends Jackal
## The smaller Fayum animals, for enemy variety: a slow scorpion that patrols, a horned viper that
## lies still on the path and a black kite that swoops along the sky. One pounce chases each off;
## the hurt, stun and run-off rules come from Jackal. Placed by overriding the script on a
## jackal.tscn instance (same body, hurtbox and ledge ray).
# ponytail: code-drawn placeholders, like the egg; swap for Paper Collage strips in the art round.

enum Kind { SCORPION, VIPER, KITE }

@export var kind := Kind.SCORPION
## Kite only: how far it flies from its start before turning, and how deep it dips.
@export var roam := 260.0
@export var swoop := 34.0

var _home := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	health = 1
	_home = position
	match kind:
		Kind.SCORPION:
			speed = 55.0
			points = 150
		Kind.VIPER:
			speed = 0.0
			points = 150
		Kind.KITE:
			speed = 130.0
			gravity = 0.0
			points = 200


func _move(delta: float) -> void:
	_t += delta
	if kind != Kind.KITE:
		super(delta)
		return
	if absf(position.x - _home.x) > roam and signf(position.x - _home.x) == dir:
		dir = -dir
	velocity.x = dir * speed
	# Steer back to the swoop curve, so a pounce's knock-up wears off
	var target_y := _home.y + sin(_t * 2.2) * swoop
	velocity.y = (target_y - position.y) * 6.0


func _animate() -> void:
	self_modulate = Color(1.6, 1.6, 1.6) if _flash > 0.0 else Color.WHITE
	queue_redraw()


func _draw() -> void:
	# Drawn facing right; mirror for left (none of these is a canon-handed character)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	match kind:
		Kind.SCORPION:
			_draw_scorpion()
		Kind.VIPER:
			_draw_viper()
		Kind.KITE:
			_draw_kite()


func _draw_scorpion() -> void:
	var body := Color("b8863b")
	var ink := Color("4a3420")
	draw_circle(Vector2(2, -6), 22.0, Color(0, 0, 0, 0.18))
	for i in 4:  # legs
		var x := -14.0 + i * 9.0
		draw_line(Vector2(x, -10), Vector2(x - 6, 0), ink, 3.0)
	draw_set_transform(Vector2(0, -14), 0.0, Vector2(dir * 1.0, 0.55))
	draw_circle(Vector2.ZERO, 20.0, body)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	# Tail curls up and over the back, sting forward
	var tail := PackedVector2Array()
	for i in 7:
		var a := PI * (0.95 - i * 0.16)
		tail.append(Vector2(-6, -30) + Vector2(cos(a), -sin(a)) * 18.0)
	draw_polyline(tail, body, 9.0, true)
	draw_circle(tail[tail.size() - 1], 4.0, Color("f2643d"))
	draw_circle(Vector2(22, -14), 6.0, body)  # pincers
	draw_circle(Vector2(22, -6), 5.0, body)
	draw_circle(Vector2(10, -17), 2.0, ink)


func _draw_viper() -> void:
	var body := Color("d9b77a")
	var spot := Color("8a6a40")
	draw_circle(Vector2(0, -6), 26.0, Color(0, 0, 0, 0.15))
	draw_set_transform(Vector2(0, -10), 0.0, Vector2(dir * 1.0, 0.45))
	draw_circle(Vector2(-6, 0), 24.0, body)
	draw_circle(Vector2(-6, 0), 13.0, spot)
	draw_circle(Vector2(-6, 0), 8.0, body)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	# Head raised a little, tasting the air
	var sway := sin(_t * 3.0) * 2.0
	draw_line(Vector2(10, -12), Vector2(20, -24 + sway), body, 9.0)
	draw_circle(Vector2(23, -26 + sway), 7.0, body)
	draw_line(Vector2(21, -31 + sway), Vector2(19, -37 + sway), spot, 2.5)  # the "horns"
	draw_circle(Vector2(26, -28 + sway), 1.6, Color("1f2433"))


func _draw_kite() -> void:
	var body := Color("6b4a32")
	var wing := Color("4a3324")
	var flap := sin(_t * 9.0) * 14.0
	draw_set_transform(Vector2(0, -24), 0.0, Vector2(dir * 1.0, 0.42))
	draw_circle(Vector2.ZERO, 22.0, body)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	draw_colored_polygon(
		PackedVector2Array([Vector2(-8, -26), Vector2(12, -26), Vector2(-14, -48 - flap)]), wing
	)
	draw_colored_polygon(  # forked tail
		PackedVector2Array(
			[Vector2(-18, -24), Vector2(-36, -32), Vector2(-30, -24), Vector2(-36, -16)]
		),
		wing
	)
	draw_circle(Vector2(20, -28), 7.0, body)
	draw_colored_polygon(
		PackedVector2Array([Vector2(26, -30), Vector2(33, -26), Vector2(25, -25)]), Color("e8b13a")
	)
	draw_circle(Vector2(22, -30), 1.6, Color("1f2433"))
