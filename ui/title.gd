extends Control
## Title screen (FR-01): Start, Controls, Settings, Quit (the browser build quits to the website).

const STAGE_2 := "res://scenes/stage_fire.tscn"

var _box: VBoxContainer


func _ready() -> void:
	_box = UiKit.overlay(self, 0.25)
	_main()


func _main() -> void:
	var body := "Survival Journey  ·  Paths by the Water\n"
	body += "Help Kai cross the scrub by the lake and get back to the den."
	if GameState.best_time > 0.0:
		body += "\nBest  %d" % GameState.best_score
	UiKit.page(_box, "The Last Wild Paw", body)
	UiKit.button(_box, "Start", GameState.start_game)
	# Stage 2 opens once Stage 1 has a best result, i.e. was cleared (ADR-010)
	var stage_2 := UiKit.button(
		_box, "Stage 2  ·  Beyond the Fire", GameState.start_game.bind(STAGE_2)
	)
	if GameState.best_time <= 0.0:
		stage_2.disabled = true
		stage_2.text = "Stage 2  ·  clear Stage 1 first"
	UiKit.button(_box, "Controls", _controls)
	UiKit.button(_box, "Settings", _settings)
	UiKit.button(_box, "Quit", GameState.quit_game)
	UiKit.focus_first(_box)


func _controls() -> void:
	UiKit.page(_box, "Controls", UiKit.controls_text())
	UiKit.button(_box, "Back", _main)
	UiKit.focus_first(_box)


func _settings() -> void:
	UiKit.page(_box, "Settings")
	UiKit.settings(_box, GameState)
	UiKit.button(_box, "Back", _main).call_deferred("grab_focus")
