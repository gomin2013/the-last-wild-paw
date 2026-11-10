extends CanvasLayer
## Stage Clear / Game Over (FR-01): the run's numbers, the best result, Next stage (after a clear,
## when there is one), Play again or Back to Home (the title screen).

## Buttons ignore input this long after the screen shows, so a held or mashed jump (Space / A is
## also ui_accept) does not skip it.
@export var input_guard := 0.5

var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_box = UiKit.overlay(self, 0.7)
	visible = false


func show_result(r: Dictionary, clear_title: String, next_stage := "") -> void:
	get_tree().paused = true
	visible = true
	var lines := [
		"Score  %d" % r["score"],
		"Food  %d    Jackals chased off  %d" % [r["food"], r["defeated"]],
		"Time  %s" % GameState.format_time(r["time"]),
	]
	if not r["cleared"] and r.has("progress"):
		lines.push_front("Made it %d%% of the way" % r["progress"])
	if r["easter_egg"]:
		lines.append("You listened, like Sera taught.")
	if r["cleared"]:
		lines.append(
			(
				"New best!"
				if r["new_best"]
				else "Best  %d  in  %s" % [r["best_score"], GameState.format_time(r["best_time"])]
			)
		)
	var title := clear_title if r["cleared"] else "Kai needs to rest"
	UiKit.page(_box, title, "\n".join(lines))
	var buttons: Array[Button] = []
	if r["cleared"] and next_stage:
		buttons.append(UiKit.button(_box, "Next stage", GameState.start_game.bind(next_stage)))
	buttons.append(
		UiKit.button(_box, "Play again" if r["cleared"] else "Try again", GameState.restart_stage)
	)
	buttons.append(UiKit.button(_box, "Back to Home", GameState.to_title))
	for b in buttons:
		b.disabled = true
	var overlay: Control = $Overlay
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.35)
	await get_tree().create_timer(input_guard).timeout
	for b in buttons:
		b.disabled = false
	UiKit.focus_first(_box)
