class_name Kai
extends CharacterBody2D
## Kai, the player: run, variable jump (coyote time + jump buffer), pounce, hurt, death. Paper
## Collage sprites from the series standees: facing left shows his LEFT side with the dark spot
## below his left eye; facing right uses its own set drawn from the right side, without it. Never
## mirror Kai.

signal hearts_changed(hearts: int, max_hearts: int)
signal died

enum State { IDLE, RUN, JUMP, FALL, POUNCE, HURT, DEAD }

const ANIMS := {
	State.IDLE: "idle",
	State.RUN: "run",
	State.JUMP: "jump",
	State.FALL: "fall",
	State.POUNCE: "pounce",
	State.HURT: "hurt",
	State.DEAD: "hurt",
}

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
@export_group("Hunger")
## Classic side-scroller pressure: hunger drains while the run is on, food fills it, an empty belly
## costs a heart and leaves starve_refill so the next heart goes a little later.
@export var max_hunger := 100.0
@export var hunger_drain := 2.5
@export var food_hunger := 40.0
@export var starve_refill := 40.0

var state := State.IDLE
var hearts := 3
var hunger := 100.0
var facing := 1

var _coyote := 0.0
var _buffer := 0.0
var _pounce_left := 0.0
var _pounce_cooldown := 0.0
var _hurt_left := 0.0
var _since_hit := 99.0
var _offsets := {}

@onready var _pounce_box: Area2D = $PounceBox
@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	hearts = max_hearts
	hunger = max_hunger
	_pounce_box.monitoring = false
	_pounce_box.body_entered.connect(_on_pounce_hit)
	_offsets = SpriteStrips.add(_sprite, "res://assets/sprites/kai/left", "left/")
	_offsets.merge(SpriteStrips.add(_sprite, "res://assets/sprites/kai/right", "right/"))


func _physics_process(delta: float) -> void:
	_since_hit += delta
	if state != State.DEAD and GameState.running:
		hunger -= hunger_drain * delta
		if hunger <= 0.0:
			hunger = starve_refill
			_take(1)
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
	modulate.a = 0.5 if _since_hit < invulnerable_time and state != State.DEAD else 1.0
	_update_sprite()


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
	hunger = minf(hunger + food_hunger, max_hunger)
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


func _update_sprite() -> void:
	var anim_name: String = ("left/" if facing < 0 else "right/") + ANIMS[state]
	SpriteStrips.play(_sprite, _offsets, anim_name)
	# The pounce lasts pounce_time; play its whole strip in that time
	var frames := _sprite.sprite_frames
	_sprite.speed_scale = (
		frames.get_frame_count(anim_name) / frames.get_animation_speed(anim_name) / pounce_time
		if state == State.POUNCE
		else 1.0
	)
