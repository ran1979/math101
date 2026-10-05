extends SceneTree
## Run: godot --headless --path . -s tests/run_tests.gd

var fails := 0
var checks := 0


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		printerr("FAIL: ", msg)


func valid(q: Dictionary) -> bool:
	return q.factor_a >= 1 and q.factor_a <= 10 and q.factor_b >= 1 and q.factor_b <= 10 \
		and q.correct_answer == q.factor_a * q.factor_b


func _init() -> void:
	var QM = load("res://scripts/question_manager.gd")
	var R = load("res://scripts/reward_manager.gd")
	var SM = load("res://scripts/save_manager.gd")

	# question generation & factor boundaries
	var qm = QM.new()
	for i in 3000:
		var q: Dictionary = qm.get_adaptive_question()
		check(valid(q), "adaptive question out of range: %s" % q)
	for t in range(1, 11):
		for i in 40:
			var q: Dictionary = qm.get_question_for_table(t)
			check(valid(q) and q.factor_b == t, "table %d question wrong: %s" % [t, q])
	check(QM.pairs_in_range(-5, 99, 0, 12).size() == 100, "pairs clamp to 1..10")
	check(QM.all_pairs().size() == 100, "100 facts")
	check(QM.fact_key(7, 3) == QM.fact_key(3, 7), "3x7 and 7x3 share a fact")

	# mastery
	qm.record_answer(3, 7, true)
	qm.record_answer(7, 3, true)
	check(qm.get_mastery(3, 7) == 2, "mastery rises on correct")
	qm.record_answer(3, 7, false)
	check(qm.get_mastery(7, 3) == 1, "mastery drops on wrong")
	for i in 10:
		qm.record_answer(2, 2, true)
	check(qm.get_mastery(2, 2) == 4, "mastery caps at 4")
	for i in 10:
		qm.record_answer(2, 2, false)
	check(qm.get_mastery(2, 2) == 0, "mastery floors at 0")
	check(qm.get_weak_facts().has("2x2"), "weak facts include 2x2")

	# adaptive selection: one weak fact among mastered ones shows up far more often
	var qa = QM.new()
	for p in QM.all_pairs():
		qa.facts[QM.fact_key(p.x, p.y)] = {"m": 4, "attempts": 4, "correct": 4, "wrong": 0, "ms": 0}
	qa.facts["6x7"]["m"] = 0
	var counts := {}
	for i in 6000:
		var q: Dictionary = qa.get_adaptive_question()
		var k: String = QM.fact_key(q.factor_a, q.factor_b)
		counts[k] = counts.get(k, 0) + 1
	var avg_other: float = (6000.0 - counts.get("6x7", 0)) / 54.0
	check(counts.get("6x7", 0) > avg_other * 4.0, "weak fact appears more (%d vs avg %.0f)" % [counts.get("6x7", 0), avg_other])
	check(qa.get_mastered_facts().size() == 54, "mastered facts listed")

	# no immediate repeats
	var last := ""
	var repeats := 0
	for i in 500:
		var q: Dictionary = qm.get_question_for_table(5)
		var k: String = QM.fact_key(q.factor_a, q.factor_b)
		if k == last:
			repeats += 1
		last = k
	check(repeats == 0, "no back-to-back repeats (%d)" % repeats)

	# rewards / XP
	check(R.xp_for_answer(true, 1) == 10, "base xp")
	check(R.xp_for_answer(true, 3) == 15, "combo xp")
	check(R.xp_for_answer(false, 0) == 3, "retry xp")
	check(R.level_index(0) == 0 and R.level_index(10 ** 6) == 4, "level bounds")
	check(R.level_index(150) == 1 and R.level_index(149) == 0, "level threshold")
	check(R.level_progress(75) == 0.5, "level progress")
	check(R.stars_for(10, 10) == 3 and R.stars_for(7, 10) == 2 and R.stars_for(0, 10) == 1, "stars")
	check(R.combo_message(3) == "COMBO x3" and R.combo_message(10) == "AMAZING STREAK!", "combo msgs")

	# daily determinism
	var d1: Array = qm.daily_questions("2026-10-05")
	var d2: Array = QM.new().daily_questions("2026-10-05")
	var d3: Array = qm.daily_questions("2026-10-06")
	var sig := func(arr): return arr.map(func(q): return "%dx%d" % [q.factor_a, q.factor_b])
	check(d1.size() == 10, "daily has 10")
	check(sig.call(d1) == sig.call(d2), "daily same for same date")
	check(sig.call(d1) != sig.call(d3), "daily changes next day")
	for q in d1:
		check(valid(q), "daily question valid")

	# save / load
	var s = SM.new()
	s.path = "user://test_save.cfg"
	s.data = SM.defaults()
	s.data["xp"] = 123
	s.data["facts"]["3x7"] = {"m": 2, "attempts": 3, "correct": 2, "wrong": 1, "ms": 0}
	s.data["settings"]["music"] = false
	s.save_data()
	var s2 = SM.new()
	s2.path = "user://test_save.cfg"
	s2.load_data()
	check(s2.data["xp"] == 123, "xp persisted")
	check(s2.data["facts"]["3x7"]["m"] == 2, "mastery persisted")
	check(s2.data["settings"]["music"] == false and s2.data["settings"]["sfx"] == true, "settings persisted")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.cfg"))
	for n in [qm, qa, s, s2]:
		n.free()

	print("%d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)
