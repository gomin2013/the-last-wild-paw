class_name Combat
extends RefCounted
## Pure combat rules, tested headless in tests/test_combat.gd.


## Health after a hit, never below zero.
static func take_damage(health: int, damage: int) -> int:
	return maxi(health - damage, 0)


## Sideways push direction for whoever is hit: away from the source (+1 when level).
static func knockback_dir(source_x: float, target_x: float) -> float:
	return 1.0 if target_x >= source_x else -1.0


## A hit lands only once the invulnerability window since the last hit has run out.
static func can_be_hit(since_last_hit: float, invulnerable_time: float) -> bool:
	return since_last_hit >= invulnerable_time
