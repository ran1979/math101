extends Control
## The question screen behind every mode: adventure, practice, speed, daily.
## Per question: generate → show → animate groups → think → answer → evaluate → record
## → feedback (+ worked explanation after a mistake) → rewards → next.

signal action_done

const PRAISE := ["AWESOME!", "GREAT JOB!", "FANTASTIC!", "YOU GOT IT!", "BRILLIANT!"]
const ENCOURAGE := ["Almost!", "Let's figure it out!", "So close!", "Let's count together!"]
const SPEED_SECONDS := 60.0

var mode := "practice"
var world := 0
var level := 0
var table := 0
var total := 10
var pool: Array = []
var daily: Array = []
var kind := "apple"
var noun := "apples"

var q: Dictionary = {}
var index := 0
var first_try := true
var input := ""
var accepting := false
var finished := false
var combo := 0
var best_combo := 0
var n_answered := 0
var n_correct := 0
var needs_practice: Array[String] = []
var xp_earned := 0
var coins_earned := 0
var time_left := SPEED_SECONDS
var running := false
var q_start := 0
var waiting_action := false
var _action_token := 0

var question_label: Label
var info_label: Label
var combo_label: Label
var vis: MultiplicationVisualizer
var avatar: ArtIcon
var message: Label
var answer_label: Label
var keypad: Keypad
var feedback: VBoxContainer
var fb_title: Label
var fb_eq: Label
var fb_text: Label
var fb_reward: Label
var action_btn: Button
var overlay: Control


func _ready() -> void:
	var s: Dictionary = Game.session
	mode = s.get("mode", "practice")
	var theme_world := 0
	match mode:
		"adventure":
			world = s.get("world", 0)
			level = s.get("level", 0)
			pool = Game.world_pool(world, level)
			total = Game.BOSS_QUESTIONS if level == Game.LEVELS_PER_WORLD - 1 else Game.LEVEL_QUESTIONS
			theme_world = world
		"practice":
			table = s.get("table", 0)
			theme_world = Game.world_for_table(table)
		"speed":
			total = 0
			theme_world = 2
		"daily":
			daily = Questions.daily_questions(Game.today())
			total = daily.size()
			theme_world = 1
	var W: Dictionary = Game.WORLDS[theme_world]
	kind = W.object
	noun = W.noun
	_build(W)
	Game.level_up.connect(_on_level_up)
	if mode == "speed" or mode == "daily":
		_show_intro()
	else:
		_next_question()


func _title() -> String:
	match mode:
		"adventure":
			return "%s · %s" % [Game.WORLDS[world].name, Game.LEVEL_NAMES[level]]
		"practice":
			return "Practice ×%d" % table if table > 0 else "Practice: Mix"
		"speed":
			return "Speed Challenge"
	return "Daily Challenge"


func _build(W: Dictionary) -> void:
	var v := UI.screen(self, W.top, W.bottom)
	var bar := UI.hbox(16)
	v.add_child(bar)
	var back := UI.button("< MAP" if mode == "adventure" else "< MENU", UI.C_SLATE, 22, Vector2(130, 56))
	back.focus_mode = FOCUS_NONE
	back.pressed.connect(_leave)
	bar.add_child(back)
	bar.add_child(UI.label(_title(), 28, Color.WHITE, 8))
	info_label = UI.label("", 22, Color.WHITE, 8)
	info_label.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.add_child(info_label)
	combo_label = UI.label("", 28, UI.GOLD, 8)
	combo_label.custom_minimum_size.x = 160
	bar.add_child(combo_label)

	var body := UI.hbox(20)
	body.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(body)
	var left := UI.vbox(12)
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.75
	body.add_child(left)
	var qcard := UI.card(Color(1, 1, 1, 0.95), 26, 4)
	left.add_child(qcard)
	question_label = UI.label("", 64, UI.INK)
	qcard.add_child(question_label)
	vis = MultiplicationVisualizer.new()
	vis.size_flags_vertical = SIZE_EXPAND_FILL
	left.add_child(vis)

	var right := UI.vbox(10)
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 400
	body.add_child(right)
	var who := UI.hbox(10)
	right.add_child(who)
	avatar = ArtIcon.new(Game.avatar(), 92)
	who.add_child(avatar)
	var bubble := UI.card(Color(1, 1, 1, 0.18), 20, 10)
	bubble.size_flags_horizontal = SIZE_EXPAND_FILL
	who.add_child(bubble)
	message = UI.label("", 22, Color.WHITE)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.x = 260
	bubble.add_child(message)
	var acard := UI.card(Color.WHITE, 24, 2)
	right.add_child(acard)
	answer_label = UI.label("?", 56, UI.INK)
	answer_label.custom_minimum_size.y = 76
	acard.add_child(answer_label)
	keypad = Keypad.new()
	keypad.size_flags_vertical = SIZE_EXPAND_FILL
	keypad.digit.connect(_type)
	keypad.erase.connect(_erase)
	keypad.submit.connect(_submit)
	right.add_child(keypad)

	feedback = UI.vbox(6)
	feedback.size_flags_vertical = SIZE_EXPAND_FILL
	feedback.hide()
	right.add_child(feedback)
	fb_title = UI.label("", 50, UI.GOLD, 14)
	fb_eq = UI.label("", 44, Color.WHITE, 10)
	fb_text = UI.label("", 26, Color.WHITE, 6)
	fb_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fb_text.custom_minimum_size.x = 300
	fb_reward = UI.label("", 26, UI.GOLD, 6)
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	action_btn = UI.button("NEXT", UI.C_GREEN, 30, Vector2(0, 76))
	action_btn.focus_mode = FOCUS_NONE
	action_btn.pressed.connect(_finish_action)
	for n in [fb_title, fb_eq, fb_text, fb_reward, spacer, action_btn]:
		feedback.add_child(n)

	overlay = UI.full_rect(Control.new())
	overlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(overlay)


# --- question flow ------------------------------------------------------------

func _pick() -> Dictionary:
	match mode:
		"adventure":
			return Questions.get_next_question(pool)
		"practice":
			return Questions.get_question_for_table(table) if table > 0 else Questions.get_adaptive_question()
		"daily":
			return daily[index - 1]
	return Questions.get_adaptive_question()


func _next_question() -> void:
	if finished:
		return
	index += 1
	q = _pick()
	first_try = true
	input = ""
	_show_input()
	question_label.text = "%d × %d = ?" % [q.factor_a, q.factor_b]
	UI.pop(question_label, 0.8)
	message.text = "How many %s are there in all?" % noun
	_update_info()
	q_start = Time.get_ticks_msec()
	vis.setup(q.factor_a, q.factor_b, kind)
	vis.show_groups(mode == "speed")


func _show_input() -> void:
	feedback.hide()
	keypad.show()
	keypad.set_enabled(true)
	answer_label.text = input if input != "" else "?"
	accepting = true


func _show_feedback() -> void:
	keypad.hide()
	feedback.show()
	action_btn.hide()
	fb_eq.text = ""
	fb_text.text = ""
	fb_reward.text = ""


func _update_info() -> void:
	if mode == "speed":
		info_label.text = "TIME: %d    SCORE: %d" % [ceili(time_left), n_correct]
	else:
		info_label.text = "Question %d / %d    Correct: %d    Needs Practice: %d" % [
			index, total, n_correct, needs_practice.size()]
	combo_label.text = "COMBO x%d" % combo if combo >= 2 else ""


func _type(d: int) -> void:
	if not accepting or input.length() >= 3:
		return
	if input == "0":
		input = ""
	input += str(d)
	answer_label.text = input


func _erase() -> void:
	if not accepting:
		return
	input = input.substr(0, input.length() - 1)
	answer_label.text = input if input != "" else "?"


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k := event as InputEventKey
	if k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
		if waiting_action:
			_finish_action()
		elif accepting:
			_submit()
	elif k.keycode == KEY_BACKSPACE or k.keycode == KEY_DELETE:
		_erase()
	elif k.keycode == KEY_ESCAPE:
		_leave()
	elif k.unicode >= 48 and k.unicode <= 57:
		_type(k.unicode - 48)
	elif k.keycode >= KEY_KP_0 and k.keycode <= KEY_KP_9:
		_type(k.keycode - KEY_KP_0)
	else:
		return
	get_viewport().set_input_as_handled()


func _submit() -> void:
	if not accepting or input == "":
		return
	accepting = false
	keypad.set_enabled(false)
	var correct := int(input) == int(q.correct_answer)
	if first_try:
		n_answered += 1
		combo = combo + 1 if correct else 0
		best_combo = maxi(best_combo, combo)
		if correct:
			n_correct += 1
		else:
			needs_practice.append("%d × %d" % [q.factor_a, q.factor_b])
	var gained: Dictionary = Game.answer(q, correct, first_try, Time.get_ticks_msec() - q_start, combo)
	_update_info()
	if correct:
		xp_earned += gained.xp
		coins_earned += gained.coins
		await _celebrate(gained)
		_advance()
	else:
		first_try = false
		await _explain()
		if finished:
			return
		if mode == "speed":
			_advance()
		else:
			input = ""
			_show_input()
			message.text = "Your turn again! How many %s in %s?" % [noun, _groups_of()]


func _advance() -> void:
	if finished:
		return
	if mode == "speed":
		if time_left <= 0.0:
			_finish()
		else:
			_next_question()
	elif index >= total:
		_finish()
	else:
		_next_question()


func _groups_of() -> String:
	return "%d %s of %d" % [q.factor_a, "group" if q.factor_a == 1 else "groups", q.factor_b]


# --- feedback -------------------------------------------------------------------

func _celebrate(gained: Dictionary) -> void:
	var a: int = q.factor_a
	var b: int = q.factor_b
	Audio.play("correct")
	if gained.coins > 0:
		Audio.play("coin")
	question_label.text = "%d × %d = %d" % [a, b, a * b]
	_show_feedback()
	fb_title.add_theme_color_override("font_color", UI.GOLD)
	fb_title.text = PRAISE.pick_random() if first_try else "THAT'S IT!"
	fb_eq.text = "%d × %d = %d" % [a, b, a * b]
	fb_text.text = "%s make%s %d!" % [_groups_of(), "s" if a == 1 else "", a * b]
	fb_reward.text = "+%d XP" % gained.xp + ("    +%d coin" % gained.coins if gained.coins > 0 else "")
	UI.pop(fb_title, 0.4)
	message.text = "Yes! Look at all %d %s!" % [a * b, noun]
	var msg := RewardManager.combo_message(combo) if first_try else ""
	if msg != "":
		_toast(msg, UI.C_PINK)
		Audio.play("celebrate")
	_confetti(70 if combo < 5 else 140)
	_cheer()
	vis.highlight_all()
	if mode == "speed":
		await _wait_action(0.8)
		return
	await vis.animate_counting(clampf(1.4 / a, 0.08, 0.25))
	action_btn.text = "NEXT"
	action_btn.show()
	await _wait_action(2.5)


func _explain() -> void:
	var a: int = q.factor_a
	var b: int = q.factor_b
	Audio.play("try")
	_show_feedback()
	fb_title.add_theme_color_override("font_color", Color("8fe8ff"))
	fb_title.text = ENCOURAGE.pick_random()
	fb_text.text = "Let's count the groups together."
	UI.pop(fb_title, 0.6)
	message.text = "Mistakes help us learn. Watch the groups!"
	answer_label.text = "?"
	var step := 0.06 if mode == "speed" else clampf(3.0 / a, 0.25, 0.6)
	await vis.show_solution(step)
	if finished:
		return
	question_label.text = "%d × %d = %d" % [a, b, a * b]
	UI.pop(question_label, 0.8)
	fb_eq.text = "%d × %d = %d" % [a, b, a * b]
	if a == 1:
		fb_text.text = "1 group with %d in it makes %d." % [b, a * b]
	else:
		fb_text.text = "%d groups with %d in each group make %d." % [a, b, a * b]
	if mode == "speed":
		await _wait_action(1.6)
	else:
		action_btn.text = "TRY AGAIN"
		action_btn.show()
		await _wait_action()


## Waits for the action button / Enter, or `auto` seconds if > 0.
func _wait_action(auto := 0.0) -> void:
	_action_token += 1
	waiting_action = true
	if auto > 0.0:
		var tw := create_tween()
		tw.tween_interval(auto)
		tw.tween_callback(_auto_action.bind(_action_token))
	await action_done


func _auto_action(token: int) -> void:
	if token == _action_token:
		_finish_action()


func _finish_action() -> void:
	if not waiting_action:
		return
	waiting_action = false
	action_btn.hide()
	action_done.emit()


func _cheer() -> void:
	var tw := avatar.create_tween()
	tw.tween_property(avatar, "scale", Vector2.ONE * 1.25, 0.15)
	tw.parallel().tween_property(avatar, "rotation", 0.2, 0.15)
	tw.tween_property(avatar, "rotation", -0.2, 0.15)
	tw.tween_property(avatar, "rotation", 0.0, 0.15)
	tw.parallel().tween_property(avatar, "scale", Vector2.ONE, 0.2)


func _toast(text: String, color: Color) -> void:
	var l := UI.label(text, 60, color, 16)
	overlay.add_child(l)
	l.size = Vector2(overlay.size.x, 90)
	l.position = Vector2(0, overlay.size.y * 0.14)
	UI.pop(l, 0.3)
	var tw := l.create_tween()
	tw.tween_interval(1.3)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


func _confetti(amount := 90) -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(overlay.size.x / 2, -20)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(overlay.size.x / 2, 10)
	p.amount = amount
	p.lifetime = 2.2
	p.one_shot = true
	p.explosiveness = 0.85
	p.direction = Vector2(0, 1)
	p.spread = 30
	p.initial_velocity_min = 150
	p.initial_velocity_max = 380
	p.gravity = Vector2(0, 420)
	p.scale_amount_min = 7
	p.scale_amount_max = 13
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	g.colors = PackedColorArray([UI.C_PINK, UI.GOLD, UI.C_GREEN, Color("4fb3ff"), UI.C_PURPLE])
	p.color_initial_ramp = g
	overlay.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _on_level_up(level_name: String) -> void:
	_toast("LEVEL UP!  %s" % level_name, UI.GOLD)
	Audio.play("level")


func _process(delta: float) -> void:
	if not running:
		return
	time_left = maxf(0.0, time_left - delta)
	_update_info()
	if time_left <= 0.0:
		running = false
		if accepting:
			_finish()


func _leave() -> void:
	Game.go("Adventure" if mode == "adventure" else "MainMenu")


# --- intro & results ------------------------------------------------------------

func _modal() -> VBoxContainer:
	var dim := UI.full_rect(ColorRect.new())
	dim.color = Color(0.04, 0.02, 0.12, 0.82)
	overlay.add_child(dim)
	var center := UI.full_rect(CenterContainer.new())
	dim.add_child(center)
	var card := UI.card(Color.WHITE, 32, 32)
	card.custom_minimum_size.x = 560
	center.add_child(card)
	var col := UI.vbox(12)
	card.add_child(col)
	return col


func _show_intro() -> void:
	var col := _modal()
	var dim := overlay.get_child(overlay.get_child_count() - 1)
	if mode == "daily":
		col.add_child(UI.label("TODAY'S CHALLENGE", 48, UI.C_PURPLE))
		col.add_child(UI.label("10 questions", 30, UI.INK))
		col.add_child(UI.label("Earn up to 3 stars!", 30, UI.INK))
		var done := Game.daily_stars()
		var stars := UI.hbox(6)
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in 3:
			stars.add_child(ArtIcon.new("star_on" if i < done else "star_off", 56))
		col.add_child(stars)
		if done > 0:
			col.add_child(UI.label("You already earned %d stars today.\nPlay again just for fun!" % done, 24, UI.C_SLATE))
	else:
		col.add_child(UI.label("SPEED CHALLENGE", 48, UI.C_ORANGE))
		col.add_child(UI.label("Answer as many as you can\nin 60 seconds!", 30, UI.INK))
		col.add_child(UI.label("Best score: %d" % Save.data["best_speed"], 28, UI.C_PURPLE))
		col.add_child(UI.label("Just for fun! The other modes have no timer.", 22, UI.C_SLATE))
	var go_btn := UI.button("START", UI.C_GREEN, 36, Vector2(0, 84))
	go_btn.focus_mode = FOCUS_NONE
	go_btn.pressed.connect(_finish_action)
	col.add_child(go_btn)
	await _wait_action()
	dim.queue_free()
	if mode == "speed":
		running = true
	_next_question()


func _finish() -> void:
	finished = true
	accepting = false
	running = false
	var stars := 0
	var title := "PRACTICE COMPLETE!"
	var lines: Array[String] = []
	var bonus := 0
	match mode:
		"adventure":
			stars = RewardManager.stars_for(n_correct, n_answered)
			var boss := level == Game.LEVELS_PER_WORLD - 1
			title = "BOSS DEFEATED!" if boss else "LEVEL COMPLETE!"
			bonus = 15 if boss else 5
			Game.complete_level(world, level, stars)
		"daily":
			stars = RewardManager.stars_for(n_correct, n_answered)
			title = "CHALLENGE COMPLETE!"
			if Game.daily_stars() == 0:
				Game.complete_daily(stars)
				bonus = 10
			else:
				lines.append("Today's stars were already saved. Great extra practice!")
		"speed":
			title = "TIME'S UP!"
			if n_correct > Save.data["best_speed"]:
				Save.data["best_speed"] = n_correct
				lines.append("NEW BEST SCORE!")
	Game.add_coins(bonus)
	coins_earned += bonus
	Save.save_data()
	Audio.play("level")
	_confetti(160)
	_show_results(title, stars, lines)


func _show_results(title: String, stars: int, lines: Array[String]) -> void:
	var col := _modal()
	col.add_child(UI.label(title, 48, UI.C_PURPLE))
	if mode == "adventure" or mode == "daily":
		var row := UI.hbox(8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(row)
		for i in 3:
			var st := ArtIcon.new("star_on" if i < stars else "star_off", 72)
			row.add_child(st)
			if i < stars:
				st.scale = Vector2.ZERO
				st.create_tween().tween_property(st, "scale", Vector2.ONE, 0.4).set_delay(0.3 + i * 0.25) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 2)
	var center := CenterContainer.new()
	center.add_child(grid)
	col.add_child(center)
	var acc := 0 if n_answered == 0 else roundi(100.0 * n_correct / n_answered)
	for pair in [["Answered", n_answered], ["Correct", n_correct], ["Accuracy", "%d%%" % acc],
			["Best combo", best_combo], ["XP earned", "+%d" % xp_earned], ["Coins earned", "+%d" % coins_earned]]:
		var k := UI.label(pair[0], 26, UI.C_SLATE)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(k)
		var v := UI.label(str(pair[1]), 26, UI.INK)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(v)
	for line in lines:
		col.add_child(UI.label(line, 26, UI.C_ORANGE))
	if not needs_practice.is_empty():
		var facts := ", ".join(needs_practice.slice(0, 6))
		var l := UI.label("Practice these next: " + facts, 24, UI.INK)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(l)
	var buttons := UI.hbox(14)
	col.add_child(buttons)
	var primary: Button
	if mode == "adventure":
		var nxt := _next_level()
		if nxt.x >= 0:
			primary = UI.button("NEXT LEVEL", UI.C_GREEN, 28, Vector2(240, 76))
			primary.pressed.connect(Game.start.bind("adventure", {"world": nxt.x, "level": nxt.y}))
		else:
			primary = UI.button("PLAY AGAIN", UI.C_GREEN, 28, Vector2(240, 76))
			primary.pressed.connect(Game.start.bind(mode, Game.session))
		var map := UI.button("MAP", UI.C_SLATE, 28, Vector2(160, 76))
		map.pressed.connect(Game.go.bind("Adventure"))
		buttons.add_child(primary)
		buttons.add_child(map)
	else:
		primary = UI.button("PLAY AGAIN", UI.C_GREEN, 28, Vector2(240, 76))
		primary.pressed.connect(Game.start.bind(mode, Game.session))
		var menu := UI.button("MENU", UI.C_SLATE, 28, Vector2(160, 76))
		menu.pressed.connect(Game.go.bind("MainMenu"))
		buttons.add_child(primary)
		buttons.add_child(menu)
	for b in buttons.get_children():
		b.size_flags_horizontal = SIZE_EXPAND_FILL
	primary.grab_focus.call_deferred()


func _next_level() -> Vector2i:
	if level < Game.LEVELS_PER_WORLD - 1:
		return Vector2i(world, level + 1)
	if world < Game.WORLDS.size() - 1:
		return Vector2i(world + 1, 0)
	return Vector2i(-1, -1)
