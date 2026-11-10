extends Node2D
## A stage (Stage 1 "Paths by the Water", S1 EP.02-03; Stage 2 "Beyond the Fire", EP.10-11): wires
## Kai to the HUD, ends the run on death or at the clear zone (the node named Den). With `sky` and
## `tint` set, the light runs from the first colour to the last as Kai crosses the stage.

## Key for the saved best result (one per stage).
@export var stage_key := "paths"
@export var clear_title := "Back at the den"
## Scene the result screen offers after a clear; empty for the last stage.
@export_file("*.tscn") var next_stage := ""
@export var stage_width := 7000
## Falling below this (should never happen) counts as a hazard and respawns Kai at the start.
@export var kill_y := 900.0
@export var sky: Gradient
@export var tint: Gradient

@onready var _kai: Kai = $Kai
@onready var _hud: Control = $HUD/Hud
@onready var _pause: CanvasLayer = $PauseMenu
@onready var _result: CanvasLayer = $Result
@onready var _start: Marker2D = $Start
@onready var _hints := $Level.find_children("Hint*", "Label", false)


func _ready() -> void:
	GameState.start_stage(stage_key)
	add_child(TouchControls.new())
	if DisplayServer.is_touchscreen_available():
		use_touch_hints()
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
	if sky and tint:
		var t := clampf(_kai.global_position.x / stage_width, 0.0, 1.0)
		$Sky/Color.color = sky.sample(t)
		var c := tint.sample(t)
		$Tint.color = c
		# Hints stay readable in the dark: undo the tint on them
		for hint in _hints:
			hint.modulate = Color(1.0 / c.r, 1.0 / c.g, 1.0 / c.b)


## On a touchscreen, hints that name keys show their `touch_text` metadata instead.
func use_touch_hints() -> void:
	for hint: Label in _hints:
		hint.text = hint.get_meta("touch_text", hint.text)


func _on_died() -> void:
	_pause.enabled = false
	await get_tree().create_timer(1.2).timeout
	_result.show_result(GameState.finish_stage(false), "")


func _on_den_reached() -> void:
	if _kai.state == Kai.State.DEAD or not GameState.running:
		return
	_pause.enabled = false
	_result.show_result(GameState.finish_stage(true), clear_title, next_stage)
