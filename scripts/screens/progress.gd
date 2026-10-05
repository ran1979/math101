extends Control
## My Progress: level, stats, weakest facts and the 10×10 mastery map.

const RATING_NAMES := ["Not tried yet", "Needs practice", "Learning", "Mastered"]
const RATING_COLORS := [Color(1, 1, 1, 0.14), Color("ffb08a"), Color("ffe17a"), Color("7fe0a4")]


func _ready() -> void:
	var v := UI.screen(self, Color("0f2a5c"), Color("1f7ae0"), "star")
	v.add_child(UI.top_bar("MY PROGRESS"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var body := UI.vbox(18)
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(body)

	var top := UI.hbox(18)
	body.add_child(top)
	top.add_child(_level_card())
	top.add_child(_weak_card())

	var st: Dictionary = Save.data["stats"]
	var acc := "-" if st["answered"] == 0 else "%d%%" % roundi(100.0 * st["correct"] / st["answered"])
	var stats := HFlowContainer.new()
	stats.add_theme_constant_override("h_separation", 12)
	stats.add_theme_constant_override("v_separation", 12)
	body.add_child(stats)
	for pair in [["Questions answered", str(st["answered"])], ["Accuracy", acc],
			["Day streak", str(Game.current_streak())], ["Total XP", str(Save.data["xp"])],
			["Tables mastered", "%d / 10" % Game.tables_mastered()], ["Best combo", str(Save.data["best_combo"])],
			["Best speed score", str(Save.data["best_speed"])]]:
		var chip := UI.card(Color(1, 1, 1, 0.95), 20, 12)
		chip.custom_minimum_size.x = 168
		var c := UI.vbox(0)
		chip.add_child(c)
		c.add_child(UI.label(pair[1], 34, UI.C_PURPLE))
		c.add_child(UI.label(pair[0], 18, UI.INK))
		stats.add_child(chip)

	body.add_child(UI.label("MULTIPLICATION MASTERY MAP", 34, Color.WHITE, 10))
	var legend := UI.hbox(24)
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(legend)
	for r in range(3, -1, -1):
		var h := UI.hbox(2)
		for i in 3:
			h.add_child(ArtIcon.new("star_on" if i < r else "star_off", 24))
		h.add_child(UI.label(" " + RATING_NAMES[r], 22, Color.WHITE, 6))
		legend.add_child(h)

	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for t in range(1, 11):
		var head := UI.card(UI.PALETTE[t % UI.PALETTE.size()], 14, 4)
		head.size_flags_horizontal = SIZE_EXPAND_FILL
		head.add_child(UI.label("×%d" % t, 30, Color.WHITE, 6))
		grid.add_child(head)
	for n in range(1, 11):
		for t in range(1, 11):
			grid.add_child(_cell(n, t))


func _rating(n: int, t: int) -> int:
	var f: Dictionary = Questions.facts.get(Questions.fact_key(n, t), {})
	if f.get("attempts", 0) == 0:
		return 0
	var m: int = f["m"]
	return 3 if m >= Questions.MAX_MASTERY else (2 if m >= 2 else 1)


func _cell(n: int, t: int) -> Control:
	var r := _rating(n, t)
	var c := UI.card(RATING_COLORS[r], 14, 6)
	c.size_flags_horizontal = SIZE_EXPAND_FILL
	c.tooltip_text = RATING_NAMES[r]
	var v := UI.vbox(2)
	c.add_child(v)
	v.add_child(UI.label("%d×%d" % [n, t], 22, UI.INK if r > 0 else Color.WHITE))
	var stars := UI.hbox(0)
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(stars)
	for i in 3:
		stars.add_child(ArtIcon.new("star_on" if i < r else "star_off", 20))
	return c


func _level_card() -> Control:
	var card := UI.card()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	var h := UI.hbox(16)
	card.add_child(h)
	h.add_child(ArtIcon.new(Game.avatar(), 110))
	var col := UI.vbox(6)
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(col)
	var xp: int = Save.data["xp"]
	var name_l := UI.label("LEVEL %d · %s" % [RewardManager.level_index(xp) + 1, RewardManager.level_name(xp)], 28, UI.C_PURPLE)
	col.add_child(name_l)
	var bar := UI.bar(UI.C_GREEN)
	bar.value = RewardManager.level_progress(xp)
	col.add_child(bar)
	var nxt := RewardManager.next_level_xp(xp)
	var next_name: String = RewardManager.level_name(nxt) if nxt > 0 else ""
	col.add_child(UI.label("%d / %d XP to %s" % [xp, nxt, next_name] if nxt > 0 else "MAX LEVEL!", 22, UI.INK))
	return card


func _weak_card() -> Control:
	var card := UI.card()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	var col := UI.vbox(8)
	card.add_child(col)
	col.add_child(UI.label("Facts to practice", 28, UI.C_ORANGE))
	var weak := Questions.get_weak_facts(8)
	if weak.is_empty():
		col.add_child(UI.label("No tricky facts yet. Keep playing!", 22, UI.INK))
		return card
	var names := weak.map(func(k): return k.replace("x", " × "))
	var l := UI.label(",  ".join(PackedStringArray(names)), 24, UI.INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(l)
	var b := UI.button("PRACTICE THEM", UI.C_GREEN, 24, Vector2(0, 56))
	b.pressed.connect(Game.start.bind("practice", {"table": 0}))
	col.add_child(b)
	return card
