extends RefCounted
var state := "idle"
var enters := 0
var exits := 0
func choose(actor: Node2D, observed: Array, health_ratio: float, visible: bool) -> Dictionary:
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or not is_finite(health_ratio) or health_ratio < 0.0 or health_ratio > 1.0:
		return {"action":"invalid"}
	var target: Node2D
	var distance := INF
	for value: Variant in observed:
		if not is_instance_valid(value) or not value is Node2D or not value.is_inside_tree() or value.is_queued_for_deletion():
			continue
		var candidate: Node2D = value
		var d := actor.global_position.distance_squared_to(candidate.global_position)
		if not is_finite(d):
			continue
		if d < distance or (is_equal_approx(d, distance) and target != null and candidate.get_instance_id() < target.get_instance_id()):
			target = candidate
			distance = d
	if target == null or not visible:
		return {"action":"idle"}
	var attack_bound := 81.0 if state == "attack" else 64.0
	var options := [{"id":0,"score":0.0,"valid":true,"action":"idle"}, {"id":1,"score":10.0,"valid":distance <= attack_bound,"action":"attack"}, {"id":2,"score":5.0,"valid":distance > attack_bound and distance <= 900.0,"action":"chase"}, {"id":3,"score":20.0,"valid":health_ratio < 0.25 and distance <= 900.0,"action":"flee"}]
	var result := best(options)
	result["target_id"] = target.get_instance_id()
	return result
func commit(next: String) -> bool:
	if next == state or next not in ["idle", "attack", "chase", "flee"]:
		return false
	if state != "idle" or enters > 0:
		exits += 1
	state = next
	enters += 1
	return true
static func better(candidate: Dictionary, current: Dictionary) -> bool:
	return bool(candidate.valid) and is_finite(float(candidate.score)) and (current.is_empty() or candidate.score > current.score or (candidate.score == current.score and candidate.id < current.id))
static func best(candidates: Array) -> Dictionary:
	var result: Dictionary = {}
	for candidate: Dictionary in candidates:
		if better(candidate, result):
			result = candidate.duplicate(true)
	return result
class Planner extends RefCounted:
	var candidates: Array = []
	var index := 0
	var epoch := 0
	var done := false
	var cancelled := false
	var result: Dictionary = {}
	func start(options: Array, generation: int) -> void:
		candidates = options.duplicate(true)
		index = 0
		epoch = generation
		done = false
		cancelled = false
		result = {}
	func step(limit: int, generation: int) -> int:
		if done:
			return 0
		if generation != epoch or limit <= 0:
			cancelled = true
			done = true
			result = {}
			return 0
		var count := 0
		while index < candidates.size() and count < limit:
			var option: Dictionary = candidates[index]
			if bool(option.valid) and is_finite(float(option.score)) and (result.is_empty() or option.score > result.score or (option.score == result.score and option.id < result.id)):
				result = option.duplicate(true)
			index += 1
			count += 1
		done = index == candidates.size()
		return count
