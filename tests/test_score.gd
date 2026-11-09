extends GutTest


func test_food_heals_when_hurt() -> void:
	assert_eq(Score.pickup(2, 3, 100), Vector2i(3, 0))


func test_food_scores_when_full() -> void:
	assert_eq(Score.pickup(3, 3, 100), Vector2i(3, 100))


func test_best_compares_score_then_time() -> void:
	assert_true(Score.is_new_best(500, 90.0, 0, 0.0), "first clear is always best")
	assert_true(Score.is_new_best(600, 120.0, 500, 90.0), "higher score wins")
	assert_false(Score.is_new_best(400, 60.0, 500, 90.0), "lower score loses even if faster")
	assert_true(Score.is_new_best(500, 80.0, 500, 90.0), "same score, faster time wins")
	assert_false(Score.is_new_best(500, 95.0, 500, 90.0))
