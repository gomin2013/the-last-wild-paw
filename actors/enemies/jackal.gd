class_name Jackal
extends CharacterBody2D
## Golden jackal (a real Fayum predator; the series shows one in S2 EP.23). Patrols, turns at walls
## and ledges, hurts Kai on touch. Pounces knock it back; after the last one it runs off the screen:
## nothing dies on screen.

const COAT := Color("9a8c7a")
const SADDLE := Color("5e554b")
const DARK := Color("2e2a26")

@export var speed := 110.0
@export var gravity := 2000.0
@export var health := 2
@export var contact_damage := 1
@export var points := 250
@export var knockback := 360.0
@export var stun_time := 0.35
@export var flee_speed := 520.0
## -1 starts walking left, 1 right.
@export var dir := -1

var _stun := 0.0
var _fleeing := false
var _flash := 0.0
var _anim := 0.0

@onready var _hurtbox: Area2D = $Hurtbox
@onready var _ledge: RayCast2D = $LedgeRay


func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, 1100.0)
	_flash = maxf(_flash - delta, 0.0)
	if _fleeing:
		velocity.x = dir * flee_speed
		modulate.a -= delta * 1.2
		if modulate.a <= 0.0:
			queue_free()
	elif _stun > 0.0:
		_stun -= delta
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
	else:
		if is_on_floor() and (is_on_wall() or not _ledge.is_colliding()):
			dir = -dir
		velocity.x = dir * speed
	_ledge.position.x = dir * 34.0
	move_and_slide()
	if not _fleeing:
		for body in _hurtbox.get_overlapping_bodies():
			if body.has_method("hurt"):
				body.hurt(contact_damage, global_position.x)
	_anim += delta * absf(velocity.x) / 24.0
	queue_redraw()


func take_pounce(source_x: float) -> void:
	if _fleeing:
		return
	health = Combat.take_damage(health, 1)
	var away := Combat.knockback_dir(source_x, global_position.x)
	velocity = Vector2(away * knockback, -220.0)
	_stun = stun_time
	_flash = 0.15
	GameState.play_sfx("hit")
	if health == 0:
		_fleeing = true
		dir = int(away)
		collision_layer = 0
		GameState.add_defeat(points)


func _p(x: float, y: float) -> Vector2:
	return Vector2(x * dir, y)


func _draw() -> void:
	var swing := sin(_anim) * 8.0
	var body_color := COAT.lightened(0.5) if _flash > 0.0 else COAT
	# Bushy tail with a dark tip
	draw_line(_p(-34, -38), _p(-58, -22), body_color, 9.0, true)
	draw_line(_p(-52, -25), _p(-60, -20), DARK, 9.0, true)
	# Long legs
	for leg: Array in [[-24.0, swing], [22.0, -swing], [-18.0, -swing], [28.0, swing]]:
		draw_line(
			_p(leg[0], -30),
			_p(leg[0] + leg[1], 0),
			SADDLE if leg[0] < -20 or leg[0] > 25 else COAT,
			6.0
		)
	# Body with a darker saddle
	draw_colored_polygon(
		[_p(-36, -34), _p(-28, -48), _p(26, -50), _p(36, -40), _p(30, -28), _p(-30, -26)],
		body_color
	)
	draw_colored_polygon([_p(-26, -46), _p(24, -48), _p(20, -42), _p(-24, -40)], SADDLE)
	# Head: long snout, tall ears
	draw_colored_polygon([_p(30, -48), _p(44, -56), _p(66, -46), _p(44, -40)], body_color)
	draw_colored_polygon([_p(36, -54), _p(38, -72), _p(46, -55)], body_color)
	draw_circle(_p(48, -50), 2.2, DARK)
	draw_circle(_p(66, -46), 2.2, DARK)
