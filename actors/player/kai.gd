class_name Kai
extends CharacterBody2D
## Kai, the player: run, variable jump (coyote time + jump buffer), pounce, hurt, death. Placeholder
## look is flat paper shapes in canon colours. Facing left shows his near (LEFT) side, so the dark
## spot below his left eye is drawn only then; facing right shows the right side without it. Never
## mirror Kai.

signal hearts_changed(hearts: int, max_hearts: int)
signal died

enum State { IDLE, RUN, JUMP, FALL, POUNCE, HURT, DEAD }

const COAT := Color("c9a36a")
const COAT_SHADE := Color("a9824e")
const MARK := Color("4a3826")
const EYE := Color("e0a030")
const EAR_IN := Color("d98f6f")

@export_group("Run")
@export var run_speed := 320.0
@export var acceleration := 2400.0
@export var friction := 2800.0
@export_group("Jump")
@export var jump_velocity := -700.0
## Upward speed is multiplied by this when jump is released early (variable height).
@export var jump_cut := 0.45
@export var gravity_up := 1800.0
@export var gravity_down := 2800.0
@export var max_fall_speed := 1100.0
@export var coyote_time := 0.1
@export var jump_buffer := 0.1
@export_group("Pounce")
@export var pounce_time := 0.18
@export var pounce_speed := 440.0
@export var pounce_cooldown := 0.35
@export_group("Hurt")
@export var max_hearts := 3
@export var invulnerable_time := 0.6
@export var hurt_time := 0.25
@export var knockback_speed := 280.0
@export var knockback_lift := -320.0

var state := State.IDLE
var hearts := 3
var facing := 1

var _coyote := 0.0
var _buffer := 0.0
var _pounce_left := 0.0
var _pounce_cooldown := 0.0
var _hurt_left := 0.0
var _since_hit := 99.0
var _anim := 0.0

@onready var _pounce_box: Area2D = $PounceBox


func _ready() -> void:
	hearts = max_hearts
	_pounce_box.monitoring = false
	_pounce_box.body_entered.connect(_on_pounce_hit)


func _physics_process(delta: float) -> void:
	_since_hit += delta
	_pounce_cooldown = maxf(_pounce_cooldown - delta, 0.0)
	var dir := Input.get_axis("move_left", "move_right")
	_coyote = coyote_time if is_on_floor() else maxf(_coyote - delta, 0.0)
	_buffer = jump_buffer if Input.is_action_just_pressed("jump") else maxf(_buffer - delta, 0.0)

	match state:
		State.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
			_fall(delta, gravity_down)
		State.POUNCE:
			_pounce_left -= delta
			velocity.x = facing * pounce_speed
			_fall(delta, gravity_down * 0.5)
			if _pounce_left <= 0.0:
				_pounce_box.set_deferred("monitoring", false)
				state = State.FALL
		State.HURT:
			_hurt_left -= delta
			velocity.x = move_toward(velocity.x, 0.0, friction * 0.4 * delta)
			_fall(delta, gravity_down)
			if _hurt_left <= 0.0:
				state = State.FALL
		_:
			_control(dir, delta)

	move_and_slide()
	if state in [State.IDLE, State.RUN, State.JUMP, State.FALL]:
		if is_on_floor():
			state = State.RUN if absf(velocity.x) > 10.0 else State.IDLE
		else:
			state = State.JUMP if velocity.y < 0.0 else State.FALL
	_anim += delta * (absf(velocity.x) / 26.0 if state == State.RUN else 2.0)
	modulate.a = 0.5 if _since_hit < invulnerable_time and state != State.DEAD else 1.0
	queue_redraw()


func _control(dir: float, delta: float) -> void:
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
		velocity.x = move_toward(velocity.x, dir * run_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_buffer = 0.0
		_coyote = 0.0
		GameState.play_sfx("jump")
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut
	_fall(delta, gravity_up if velocity.y < 0.0 else gravity_down)
	if Input.is_action_just_pressed("attack") and _pounce_cooldown <= 0.0:
		state = State.POUNCE
		_pounce_left = pounce_time
		_pounce_cooldown = pounce_time + pounce_cooldown
		_pounce_box.scale.x = facing
		_pounce_box.set_deferred("monitoring", true)
		GameState.play_sfx("pounce")


func _fall(delta: float, gravity: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


## Touch damage from an enemy at source_x. Ignored while invulnerable or mid-pounce (the pounce
## wins).
func hurt(damage: int, source_x: float) -> bool:
	if state in [State.DEAD, State.POUNCE] or not Combat.can_be_hit(_since_hit, invulnerable_time):
		return false
	_take(damage)
	if state != State.DEAD:
		state = State.HURT
		_hurt_left = hurt_time
	velocity = Vector2(
		Combat.knockback_dir(source_x, global_position.x) * knockback_speed, knockback_lift
	)
	return true


## Hazards always send Kai back to a safe spot; they cost a heart unless he is still invulnerable.
func hit_hazard(damage: int, respawn: Vector2) -> void:
	if state == State.DEAD:
		return
	if Combat.can_be_hit(_since_hit, invulnerable_time):
		_take(damage)
	if state == State.DEAD:
		return
	global_position = respawn
	velocity = Vector2.ZERO
	state = State.FALL
	_pounce_box.set_deferred("monitoring", false)


func eat(points: int) -> void:
	var result := Score.pickup(hearts, max_hearts, points)
	if result.x != hearts:
		hearts = result.x
		hearts_changed.emit(hearts, max_hearts)
	GameState.add_food(result.y)


func is_still() -> bool:
	return state == State.IDLE and is_on_floor()


func _take(damage: int) -> void:
	hearts = Combat.take_damage(hearts, damage)
	_since_hit = 0.0
	hearts_changed.emit(hearts, max_hearts)
	GameState.play_sfx("hurt")
	if hearts == 0:
		state = State.DEAD
		_pounce_box.set_deferred("monitoring", false)
		died.emit()


func _on_pounce_hit(body: Node2D) -> void:
	if body.has_method("take_pounce"):
		body.take_pounce(global_position.x)


func _p(x: float, y: float) -> Vector2:
	return Vector2(x * facing, y)


func _draw() -> void:
	var stretch := 1.25 if state == State.POUNCE else 1.0
	var low := 10.0 if state == State.DEAD else 0.0
	var air := state in [State.JUMP, State.FALL]
	var swing := sin(_anim) * 7.0 if state == State.RUN else 0.0

	# Ringed tail with a dark tip, carried low behind him
	var tail: PackedVector2Array = []
	for i in 7:
		var t := i / 6.0
		tail.append(_p((-26.0 - 34.0 * t) * stretch, -26.0 + low - 10.0 * t + sin(t * 3.0) * 6.0))
	for i in 6:
		var c := MARK if i == 5 or i % 2 == 1 else COAT_SHADE
		draw_line(tail[i], tail[i + 1], c, 8.0 - i * 0.4, true)

	# Legs: far pair darker, near pair with dark bands
	var legs := [
		[-20.0, swing, COAT_SHADE],
		[14.0, -swing, COAT_SHADE],
		[-14.0, -swing, COAT],
		[20.0, swing, COAT]
	]
	for leg: Array in legs:
		var lx: float = leg[0] * stretch
		var foot := _p(lx + (leg[1] as float), -2.0 + low) if not air else _p(lx + 6.0, -12.0)
		draw_line(_p(lx, -22.0 + low), foot, leg[2], 7.0, true)
		draw_line(
			foot.lerp(_p(lx, -22.0 + low), 0.35), foot.lerp(_p(lx, -22.0 + low), 0.5), MARK, 7.0
		)

	# Body
	var body: PackedVector2Array = [
		_p(-30 * stretch, -24 + low),
		_p(-22 * stretch, -36 + low),
		_p(18 * stretch, -38 + low),
		_p(30 * stretch, -30 + low),
		_p(26 * stretch, -20 + low),
		_p(-26 * stretch, -18 + low),
	]
	draw_colored_polygon(body, COAT)
	draw_line(_p(-18 * stretch, -35 + low), _p(14 * stretch, -37 + low), COAT_SHADE, 3.0)

	# Head, ears, eye, nose
	var hx := 34.0 * stretch
	var hy := -40.0 + low + (4.0 if state == State.POUNCE else 0.0)
	draw_colored_polygon(
		[
			_p(hx - 10, hy - 8),
			_p(hx + 6, hy - 10),
			_p(hx + 16, hy),
			_p(hx + 8, hy + 8),
			_p(hx - 8, hy + 8)
		],
		COAT
	)
	draw_colored_polygon([_p(hx - 8, hy - 7), _p(hx - 4, hy - 20), _p(hx + 1, hy - 8)], COAT)
	draw_colored_polygon([_p(hx - 6, hy - 8), _p(hx - 4, hy - 16), _p(hx - 1, hy - 8)], EAR_IN)
	draw_circle(_p(hx + 4, hy - 2), 2.6, EYE)
	draw_circle(_p(hx + 4.6, hy - 2), 1.1, MARK)
	draw_circle(_p(hx + 16, hy), 1.8, MARK)
	if facing < 0:
		draw_circle(_p(hx + 4, hy + 3.5), 1.8, MARK)  # the spot below his LEFT eye
