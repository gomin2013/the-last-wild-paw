class_name Score
extends RefCounted
## Pure scoring rules, tested headless in tests/test_score.gd.


## Food heals one heart when Kai is hurt, otherwise it scores.
## Returns Vector2i(new_hearts, points_scored).
static func pickup(hearts: int, max_hearts: int, points: int) -> Vector2i:
	if hearts < max_hearts:
		return Vector2i(hearts + 1, 0)
	return Vector2i(hearts, points)


## A cleared run beats the saved best on score, then on time. best_time <= 0 means no best yet.
static func is_new_best(score: int, time: float, best_score: int, best_time: float) -> bool:
	if best_time <= 0.0:
		return true
	if score != best_score:
		return score > best_score
	return time < best_time


## How far Kai got, 0-100: his x between the start and the clear zone.
static func progress(x: float, start_x: float, end_x: float) -> int:
	if end_x <= start_x:
		return 100
	return roundi(clampf((x - start_x) / (end_x - start_x), 0.0, 1.0) * 100.0)
