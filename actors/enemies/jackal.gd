class_name Jackal
extends CharacterBody2D
## Golden jackal (a real Fayum predator; the series shows one in S2 EP.23). Patrols, turns at walls
## and ledges, hurts Kai on touch. Pounces knock it back; after the last one it runs off the screen:
## nothing dies on screen.

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
var _offsets := {}

@onready var _hurtbox: Area2D = $Hurtbox
@onready var _ledge: RayCast2D = $LedgeRay
@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_offsets = SpriteStrips.add(_sprite, "res://assets/sprites/jackal")


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
		_move(delta)
	_ledge.position.x = dir * 34.0
	move_and_slide()
	if not _fleeing:
		for body in _hurtbox.get_overlapping_bodies():
			if body.has_method("hurt"):
				body.hurt(contact_damage, global_position.x)
	_animate()


## Patrol: turn at walls and ledges. The other animals (viper, kite, scorpion) extend Jackal and
## override _move and _animate; the pounce, stun and run-off rules stay shared.
func _move(_delta: float) -> void:
	if is_on_floor() and (is_on_wall() or not _ledge.is_colliding()):
		dir = -dir
	velocity.x = dir * speed


func _animate() -> void:
	# The strips face left; the jackal is not a canon-handed character, so flipping is fine
	SpriteStrips.play(_sprite, _offsets, "defeat" if _fleeing else "hit" if _stun > 0.0 else "walk")
	_sprite.flip_h = dir > 0
	_sprite.offset.x *= -1.0 if dir > 0 else 1.0
	_sprite.modulate = Color(1.6, 1.6, 1.6) if _flash > 0.0 else Color.WHITE


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
