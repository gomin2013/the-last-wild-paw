extends CanvasLayer
## Pause anywhere during play (FR-01): Resume, Restart, Controls, Settings, Back to Home
## (the title screen).

var enabled := true

var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_box = UiKit.overlay(self)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if visible:
		_resume()
	else:
		get_tree().paused = true
		visible = true
		_main()


func _main() -> void:
	UiKit.page(_box, "Paused")
	UiKit.button(_box, "Resume", _resume)
	UiKit.button(_box, "Restart", GameState.restart_stage)
	UiKit.button(_box, "Controls", _controls)
	UiKit.button(_box, "Settings", _settings)
	UiKit.button(_box, "Back to Home", GameState.to_title)
	UiKit.focus_first(_box)


func _controls() -> void:
	UiKit.page(_box, "Controls", UiKit.controls_text())
	UiKit.button(_box, "Back", _main)
	UiKit.focus_first(_box)


func _settings() -> void:
	UiKit.page(_box, "Settings")
	UiKit.settings(_box, GameState)
	UiKit.button(_box, "Back", _main).call_deferred("grab_focus")


func _resume() -> void:
	visible = false
	get_tree().paused = false
