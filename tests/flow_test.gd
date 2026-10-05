extends Node
## End-to-end: plays every mode to its results screen, mixing right and wrong answers.
## Run: godot --headless --path . res://tests/FlowTest.tscn

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: ", msg)


func _ready() -> void:
	Save.path = "user://flow_test.cfg"
	Save.reset()
	Save.data["avatar"] = "dragon"
	Game.sync_data()
	Engine.time_scale = 20.0

	for w in Game.WORLDS.size():
		for l in Game.LEVELS_PER_WORLD:
			check(Game.level_unlocked(w, l), "unlocked %d_%d" % [w, l])
			await play("adventure", {"world": w, "level": l})
			check(Game.level_stars(w, l) >= 1, "stars for %d_%d" % [w, l])
	await play("practice", {"table": 7})
	await play("practice", {"table": 0})
	await play("daily", {})
	check(Game.daily_stars() >= 1, "daily stars saved")
	await play("speed", {})
	check(Save.data["best_speed"] > 0, "best speed saved")

	var st: Dictionary = Save.data["stats"]
	check(st["answered"] > 100 and st["correct"] < st["answered"], "stats recorded")
	check(Save.data["xp"] > 0 and Save.data["coins"] > 0 and Save.data["stars"] >= 21, "rewards")
	check(not Questions.get_weak_facts().is_empty(), "weak facts tracked")
	Save.load_data()  # what a browser refresh would see
	check(Save.data["stats"]["answered"] == st["answered"], "progress persists after reload")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))
	print("flow test: %d failures" % fails)
	get_tree().quit(1 if fails else 0)


func play(mode: String, opts: Dictionary) -> void:
	Game.session = opts.duplicate()
	Game.session["mode"] = mode
	var quiz: Control = load("res://scenes/Quiz.tscn").instantiate()
	add_child(quiz)
	var n := 0
	var frames := 0
	while not quiz.finished and frames < 60000:
		frames += 1
		await get_tree().process_frame
		if mode == "speed" and n > 12:
			quiz.time_left = 0.0
		if quiz.waiting_action:
			quiz._finish_action()
		elif quiz.accepting:
			n += 1
			var right: int = quiz.q.correct_answer
			check(quiz.vis.a == quiz.q.factor_a and quiz.vis.b == quiz.q.factor_b, "visual matches question")
			# every 3rd question: wrong first, then correct on retry
			var ans := right + 1 if (n % 3 == 0 and quiz.first_try) else right
			for ch in str(ans):
				quiz._type(int(ch))
			quiz._submit()
	check(quiz.finished, "%s finished (%d answers)" % [mode, n])
	check(quiz.overlay.get_child_count() > 0, "%s results shown" % mode)
	quiz.queue_free()
	await get_tree().process_frame
