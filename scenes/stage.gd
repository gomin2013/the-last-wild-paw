extends Node2D
## Stage 1 "Paths by the Water" (S1 EP.02-03): wires Kai to the HUD, ends the run on death or at the
## den.

@export var stage_width := 7000
## Falling below this (should never happen) counts as a hazard and respawns Kai at the start.
@export var kill_y := 900.0

@onready var _kai: Kai = $Kai
@onready var _hud: Control = $HUD/Hud
@onready var _pause: CanvasLayer = $PauseMenu
@onready var _result: CanvasLayer = $Result
@onready var _start: Marker2D = $Start


func _ready() -> void:
	GameState.start_stage()
	var cam: Camera2D = _kai.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_right = stage_width
	cam.limit_top = -240
	cam.limit_bottom = 720
	_kai.global_position = _start.global_position
	_kai.hearts_changed.connect(_hud.set_hearts)
	_hud.set_hearts(_kai.hearts, _kai.max_hearts)
	_kai.died.connect(_on_died)
	$Den.reached.connect(_on_den_reached)


func _physics_process(_delta: float) -> void:
	if _kai.global_position.y > kill_y:
		_kai.hit_hazard(1, _start.global_position)


func _on_died() -> void:
	_pause.enabled = false
	await get_tree().create_timer(1.2).timeout
	_result.show_result(GameState.finish_stage(false))


func _on_den_reached() -> void:
	if _kai.state == Kai.State.DEAD or not GameState.running:
		return
	_pause.enabled = false
	_result.show_result(GameState.finish_stage(true))
