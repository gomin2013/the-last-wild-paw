extends GutTest


func test_damage_floors_at_zero() -> void:
	assert_eq(Combat.take_damage(3, 1), 2)
	assert_eq(Combat.take_damage(1, 2), 0)


func test_knockback_pushes_away_from_source() -> void:
	assert_eq(Combat.knockback_dir(100.0, 150.0), 1.0)
	assert_eq(Combat.knockback_dir(150.0, 100.0), -1.0)
	assert_eq(Combat.knockback_dir(100.0, 100.0), 1.0)


func test_invulnerability_window() -> void:
	assert_false(Combat.can_be_hit(0.3, 0.6))
	assert_true(Combat.can_be_hit(0.6, 0.6))
