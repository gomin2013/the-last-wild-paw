extends GutTest
## Smoke tests on the real stage scene: it loads, Kai can move, a jackal can be chased off, the den
## clears the run.

const STAGE := preload("res://scenes/stage_paths.tscn")

var _stage: Node2D
var _kai: Kai


func before_all() -> void:
	GameState.save_path = "user://test_save.cfg"


func before_each() -> void:
	_stage = STAGE.instantiate()
	add_child_autofree(_stage)
	_kai = _stage.get_node("Kai")
	await wait_physics_frames(30)


func after_each() -> void:
	GameState.checkpoint = {}
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


func test_game_over_shows_progress_after_the_hit_stop() -> void:
	_kai.hurt(3, _kai.global_position.x - 10.0)
	assert_eq(_kai.state, Kai.State.DEAD)
	assert_lt(Engine.time_scale, 1.0, "hit-stop slows the world")
	# The result pauses the tree, which stalls GUT waits: this timer runs paused, in real time
	await get_tree().create_timer(1.4, true, false, true).timeout
	assert_eq(Engine.time_scale, 1.0, "hit-stop ends")
	var result: CanvasLayer = _stage.get_node("Result")
	assert_true(result.visible, "the game-over screen is up")
	var buttons := result.find_children("*", "Button", true, false)
	assert_true(buttons[0].disabled, "buttons ignore input at first")
	assert_string_contains(result.find_children("*", "Label", true, false)[1].text, "% of the way")
	await get_tree().create_timer(0.6, true, false, true).timeout
	assert_false(buttons[0].disabled, "then they work")


func test_checkpoint_keeps_the_spot_and_the_run_for_a_retry() -> void:
	var cairn_x: float = _stage.get_node("Level/Checkpoint1").global_position.x
	GameState.add_bonus(300)
	_kai.global_position = Vector2(cairn_x, 530)
	await wait_physics_frames(4)
	assert_eq(GameState.checkpoint_x(), cairn_x, "the cairn is saved")
	GameState.add_bonus(999)  # scored after the cairn: lost on a retry
	# What "Try again" does: the same stage comes back
	_stage.free()
	_stage = STAGE.instantiate()
	add_child_autofree(_stage)
	_kai = _stage.get_node("Kai")
	await wait_physics_frames(10)
	assert_almost_eq(_kai.global_position.x, cairn_x, 4.0, "Kai starts at the cairn")
	assert_eq(GameState.score, 300, "score as it was at the cairn")


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


func test_an_empty_belly_costs_a_heart_and_food_refills_it() -> void:
	_kai.hunger = 0.01
	await wait_physics_frames(2)
	assert_eq(_kai.hearts, 2, "starving costs a heart")
	assert_almost_eq(_kai.hunger, _kai.starve_refill, 1.0, "and leaves a little hunger")
	_kai.eat(100)
	assert_gt(_kai.hunger, _kai.starve_refill + 30.0, "food fills the belly")


func test_one_pounce_chases_each_small_animal_off_and_the_kite_stays_up() -> void:
	var kite: Critter = _stage.get_node("Kite1")
	var start_y := kite.position.y
	await wait_physics_frames(30)
	assert_almost_eq(kite.position.y, start_y, kite.swoop + 4.0, "the kite flies, it does not fall")
	for n: String in ["Viper1", "Scorpion1", "Kite1"]:
		var c: Critter = _stage.get_node(n)
		c.take_pounce(c.global_position.x - 50.0)
		assert_eq(c.collision_layer, 0, n + " runs off after one pounce")


func test_eggs_come_often_enough_to_outrun_hunger() -> void:
	# Half run speed allows for jumps, fights and backtracking
	var xs: Array[float] = [_stage.get_node("Start").global_position.x]
	for egg in _stage.get_node("Level").find_children("Egg*", "Area2D", false):
		xs.append(egg.global_position.x)
	xs.append(_stage.get_node("Den").global_position.x)
	xs.sort()
	for i in range(1, xs.size()):
		var secs: float = (xs[i] - xs[i - 1]) / (_kai.run_speed * 0.5)
		assert_lt(secs * _kai.hunger_drain, _kai.max_hunger, "egg gap at x %d is too long" % xs[i])
	assert_gt(_stage.get_node("Den").global_position.x, 11000.0, "stage 1 has its long second half")
