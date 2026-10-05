extends Node
## QuestionManager: builds multiplication questions (always 1..10 × 1..10) and tracks
## mastery per fact, so weak facts come up more often.
## 3×7 and 7×3 share one mastery record, but both orientations are asked.

const MIN_FACTOR := 1
const MAX_FACTOR := 10
const MAX_MASTERY := 4
const MASTERY_NAMES := ["unknown", "learning", "improving", "familiar", "mastered"]
const WEIGHTS := [8.0, 6.0, 4.0, 2.0, 1.0]  # by mastery: weaker facts are picked more often
const RECENT_SIZE := 4  # don't repeat any of the last few facts when the pool allows it

var facts: Dictionary = {}
var recent: Array[String] = []
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


static func fact_key(a: int, b: int) -> String:
	return "%dx%d" % [mini(a, b), maxi(a, b)]


static func is_valid(a: int, b: int) -> bool:
	return a >= MIN_FACTOR and a <= MAX_FACTOR and b >= MIN_FACTOR and b <= MAX_FACTOR


static func pairs_in_range(a_lo: int, a_hi: int, b_lo: int, b_hi: int) -> Array:
	var out := []
	for x in range(maxi(a_lo, MIN_FACTOR), mini(a_hi, MAX_FACTOR) + 1):
		for y in range(maxi(b_lo, MIN_FACTOR), mini(b_hi, MAX_FACTOR) + 1):
			out.append(Vector2i(x, y))
	return out


static func all_pairs() -> Array:
	return pairs_in_range(MIN_FACTOR, MAX_FACTOR, MIN_FACTOR, MAX_FACTOR)


static func difficulty(a: int, b: int) -> int:
	# 1 = easy (×1, ×2, ×10, small products), 2 = medium, 3 = hard
	if mini(a, b) <= 2 or a == 10 or b == 10 or a * b <= 20:
		return 1
	return 2 if a * b <= 40 else 3


func get_mastery(a: int, b: int) -> int:
	var f: Dictionary = facts.get(fact_key(a, b), {})
	return int(f.get("m", 0))


func make_question(a: int, b: int) -> Dictionary:
	assert(is_valid(a, b), "factor out of range")
	var f: Dictionary = facts.get(fact_key(a, b), {})
	return {
		"factor_a": a,
		"factor_b": b,
		"correct_answer": a * b,
		"difficulty": difficulty(a, b),
		"mastery": int(f.get("m", 0)),
		"attempts": int(f.get("attempts", 0)),
		"correct": int(f.get("correct", 0)),
		"incorrect": int(f.get("wrong", 0)),
	}


## Returns the fact's new mastery (0..4).
func record_answer(a: int, b: int, correct: bool, ms := 0) -> int:
	var k := fact_key(a, b)
	if not facts.has(k):
		facts[k] = {"m": 0, "attempts": 0, "correct": 0, "wrong": 0, "ms": 0}
	var f: Dictionary = facts[k]
	f["attempts"] += 1
	f["ms"] += ms
	if correct:
		f["correct"] += 1
		f["m"] = mini(MAX_MASTERY, int(f["m"]) + 1)
	else:
		f["wrong"] += 1
		f["m"] = maxi(0, int(f["m"]) - 1)
	return f["m"]


func weight(p: Vector2i) -> float:
	return WEIGHTS[get_mastery(p.x, p.y)]


## Weighted pick from (a, b) pairs: low mastery = higher chance.
func pick_from(pairs: Array) -> Dictionary:
	var pool: Array = pairs.filter(func(p): return not recent.has(fact_key(p.x, p.y)))
	if pool.is_empty():
		pool = pairs
	var total := 0.0
	for p in pool:
		total += weight(p)
	var roll := rng.randf() * total
	var chosen: Vector2i = pool[pool.size() - 1]
	for p in pool:
		roll -= weight(p)
		if roll <= 0.0:
			chosen = p
			break
	recent.append(fact_key(chosen.x, chosen.y))
	while recent.size() > mini(RECENT_SIZE, pairs.size() / 2):
		recent.pop_front()
	return make_question(chosen.x, chosen.y)


func get_adaptive_question() -> Dictionary:
	return pick_from(all_pairs())


## "×7 table" questions are n × 7: n groups of 7.
func get_question_for_table(table: int) -> Dictionary:
	return pick_from(pairs_in_range(MIN_FACTOR, MAX_FACTOR, table, table))


func get_next_question(pool: Array = []) -> Dictionary:
	return pick_from(pool if not pool.is_empty() else all_pairs())


## Fact keys like "6x7", weakest first.
func get_weak_facts(limit := 6) -> Array:
	var out := []
	for k in facts:
		if facts[k]["wrong"] > 0 and facts[k]["m"] <= 2:
			out.append(k)
	out.sort_custom(func(x, y) -> bool:
		if facts[x]["m"] != facts[y]["m"]:
			return facts[x]["m"] < facts[y]["m"]
		return facts[x]["wrong"] > facts[y]["wrong"]
	)
	return out.slice(0, limit)


func get_mastered_facts() -> Array:
	return facts.keys().filter(func(k): return facts[k]["m"] >= MAX_MASTERY)


## Same date → same 10 questions; different facts each.
func daily_questions(date: String, count := 10) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = hash("multiply-quest:" + date)
	var pairs := all_pairs()
	for i in range(pairs.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var tmp = pairs[i]
		pairs[i] = pairs[j]
		pairs[j] = tmp
	var out := []
	var seen := {}
	for p in pairs:
		var k := fact_key(p.x, p.y)
		if seen.has(k):
			continue
		seen[k] = true
		out.append(make_question(p.x, p.y))
		if out.size() == count:
			break
	return out
