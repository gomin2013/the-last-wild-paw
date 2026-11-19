extends GutTest
## Stage 2 "Beyond the Fire": it loads, every hazard has a respawn, the water sends Kai back, the
## offering stone clears the run, and its best result is kept apart from Stage 1's.

var _stage: Node2D
var _kai: Kai


func before_all() -> void:
	GameState.save_path = "user://test_save.cfg"


func before_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_path))
	_stage = load("res://scenes/stage_fire.tscn").instantiate()
	add_child_autofree(_stage)
	_kai = _stage.get_node("Kai")
	await wait_physics_frames(30)


func after_each() -> void:
	get_tree().paused = false


func test_kai_lands_at_dusk() -> void:
	assert_true(_kai.is_on_floor(), "Kai stands on the start ground")
	assert_eq(GameState.stage_key, "fire")


func test_water_sends_kai_to_its_respawn() -> void:
	for hazard: Thorns in _stage.find_children("*", "Thorns"):
		assert_not_null(hazard.respawn, "%s has a respawn marker" % hazard.name)
	var water: Thorns = _stage.get_node("Level/Water")
	_kai.global_position = water.global_position + Vector2(40, 20)
	await wait_physics_frames(3)
	assert_almost_eq(_kai.global_position.x, water.respawn.global_position.x, 2.0)


func test_offering_clears_and_keeps_its_own_best() -> void:
	GameState.add_bonus(300)
	_kai.global_position = _stage.get_node("Den").global_position + Vector2(0, -4)
	await wait_physics_frames(4)
	assert_false(GameState.running, "the run ended")
	assert_eq(GameState.best_score, 300)
	GameState.start_stage("paths")
	assert_eq(GameState.best_score, 0, "Stage 1's best is untouched")


func test_title_locks_stage_2_until_stage_1_is_cleared() -> void:
	var saved := GameState.best_time
	for cleared in [false, true]:
		GameState.best_time = 95.0 if cleared else 0.0
		var title: Control = load("res://scenes/main.tscn").instantiate()
		add_child_autofree(title)
		var stage_2: Button
		for b: Button in title.find_children("*", "Button", true, false):
			if b.text.begins_with("Stage 2"):
				stage_2 = b
		assert_eq(stage_2.disabled, not cleared, "locked unless Stage 1 has a best")
	GameState.best_time = saved


func test_food_comes_often_enough_to_outrun_hunger() -> void:
	# Half run speed allows for jumps, fights and backtracking
	var xs: Array[float] = [_stage.get_node("Start").global_position.x]
	for f in _stage.get_node("Level").find_children("Food*", "Area2D", false):
		xs.append(f.global_position.x)
	xs.append(_stage.get_node("Den").global_position.x)
	xs.sort()
	for i in range(1, xs.size()):
		var secs: float = (xs[i] - xs[i - 1]) / (_kai.run_speed * 0.5)
		assert_lt(secs * _kai.hunger_drain, _kai.max_hunger, "food gap at x %d is too long" % xs[i])
	assert_gt(_stage.get_node("Den").global_position.x, 11000.0, "stage 2 has its long middle")
