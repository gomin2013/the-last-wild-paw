extends GutTest
## Smoke tests on the real stage scene: it loads, Kai can move, a jackal can be chased off, the den
## clears the run.

var _stage: Node2D
var _kai: Kai


func before_all() -> void:
	GameState.save_path = "user://test_save.cfg"


func before_each() -> void:
	_stage = load("res://scenes/stage_paths.tscn").instantiate()
	add_child_autofree(_stage)
	_kai = _stage.get_node("Kai")
	await wait_physics_frames(30)


func after_each() -> void:
	Input.action_release("move_right")
	get_tree().paused = false


func test_kai_lands_and_runs_right() -> void:
	assert_true(_kai.is_on_floor(), "Kai stands on the start ground")
	var x := _kai.global_position.x
	Input.action_press("move_right")
	await wait_physics_frames(30)
	assert_gt(_kai.global_position.x, x + 100.0, "move_right moves Kai")


func test_two_pounces_chase_a_jackal_off() -> void:
	var jackal: Jackal = _stage.get_node("Jackal1")
	var before := GameState.defeated
	jackal.take_pounce(jackal.global_position.x - 50.0)
	assert_eq(GameState.defeated, before, "one pounce only knocks it back")
	jackal.take_pounce(jackal.global_position.x - 50.0)
	assert_eq(GameState.defeated, before + 1)
	assert_eq(jackal.collision_layer, 0, "a fleeing jackal no longer blocks Kai")


func test_food_heals_a_hurt_kai() -> void:
	_kai.hurt(1, _kai.global_position.x - 10.0)
	assert_eq(_kai.hearts, 2)
	_kai.eat(100)
	assert_eq(_kai.hearts, 3)


func test_reaching_the_den_clears_the_stage() -> void:
	_kai.global_position = _stage.get_node("Den").global_position + Vector2(0, -4)
	await wait_physics_frames(4)
	assert_false(GameState.running, "the run ended")
	assert_true(_stage.get_node("Result").visible, "the result screen is up")


func test_thorns_send_kai_to_their_respawn() -> void:
	for thorns: Thorns in _stage.find_children("*", "Thorns"):
		assert_not_null(thorns.respawn, "%s has a respawn marker" % thorns.name)
	var thorns: Thorns = _stage.get_node("Level/Thorns1")
	_kai.global_position = thorns.global_position + Vector2(40, 20)
	await wait_physics_frames(3)
	var back_x := thorns.respawn.global_position.x
	assert_almost_eq(_kai.global_position.x, back_x, 2.0, "back to the respawn")


func test_touch_buttons_press_real_actions() -> void:
	var buttons := _stage.find_children("*", "TouchScreenButton", true, false)
	assert_eq(buttons.size(), 5, "left, right, pounce, jump, pause")
	for b: TouchScreenButton in buttons:
		assert_true(InputMap.has_action(b.action), "%s is an input action" % b.action)
	var layer: CanvasLayer = buttons[0].get_parent()
	await wait_process_frames(2)
	assert_eq(
		layer.visible, DisplayServer.is_touchscreen_available(), "glyphs hidden without touch"
	)


func test_touch_hints_drop_keyboard_keys() -> void:
	_stage.use_touch_hints()
	assert_string_starts_with(_stage.get_node("Level/HintJump").text, "Big right button")
	assert_string_starts_with(_stage.get_node("Level/HintThorns").text, "Thorns", "no meta: kept")


func test_controls_text_names_touch_buttons_only_on_touch() -> void:
	assert_string_starts_with(UiKit.controls_text(true), "Touch:")
	assert_string_starts_with(UiKit.controls_text(false), "Run:")
