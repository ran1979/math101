extends Control


func _ready() -> void:
	var v := UI.screen(self, Color("2a1b6e"), Color("c2448b"), "apple,coin,star,gem")
	var row := UI.hbox(36)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(row)

	var left := UI.vbox(12)
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.7
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(left)
	left.add_child(UI.label("MULTIPLY QUEST", 80, UI.GOLD, 20))
	left.add_child(UI.label("Master the multiplication table!", 32, Color.WHITE, 10))
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	left.add_child(gap)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	left.add_child(grid)
	var items := [
		["PLAY", UI.C_ORANGE, Game.go.bind("Adventure")],
		["PRACTICE", UI.C_GREEN, Game.go.bind("Practice")],
		["SPEED CHALLENGE", UI.C_YELLOW, Game.start.bind("speed", {})],
		["DAILY CHALLENGE", UI.C_PURPLE, Game.start.bind("daily", {})],
		["MY PROGRESS", UI.C_BLUE, Game.go.bind("Progress")],
		["SETTINGS", UI.C_SLATE, Game.go.bind("Settings")],
	]
	var first: Button = null
	for it in items:
		var b := UI.button(it[0], it[1], 30, Vector2(320, 88))
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.pressed.connect(it[2])
		grid.add_child(b)
		if first == null:
			first = b

	row.add_child(_player_card())
	if Save.data["avatar"] == "":
		_avatar_picker()
	else:
		first.grab_focus.call_deferred()


func _player_card() -> Control:
	var card := UI.card()
	card.size_flags_vertical = SIZE_SHRINK_CENTER
	card.custom_minimum_size.x = 360
	var col := UI.vbox(10)
	card.add_child(col)
	var hero := ArtIcon.new(Game.avatar(), 170)
	hero.size_flags_horizontal = SIZE_SHRINK_CENTER
	col.add_child(hero)
	var tw := hero.create_tween().set_loops()
	tw.tween_property(hero, "rotation", 0.07, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(hero, "rotation", -0.07, 1.2).set_trans(Tween.TRANS_SINE)
	var xp: int = Save.data["xp"]
	col.add_child(UI.label("LEVEL %d" % (RewardManager.level_index(xp) + 1), 34, UI.C_PURPLE))
	col.add_child(UI.label(RewardManager.level_name(xp), 26, UI.INK))
	var bar := UI.bar(UI.C_GREEN)
	bar.value = RewardManager.level_progress(xp)
	col.add_child(bar)
	var nxt := RewardManager.next_level_xp(xp)
	col.add_child(UI.label("%d / %d XP" % [xp, nxt] if nxt > 0 else "%d XP · MAX LEVEL" % xp, 22, UI.C_SLATE))
	var w := UI.hbox(8)
	w.alignment = BoxContainer.ALIGNMENT_CENTER
	for pair in [["coin", Save.data["coins"]], ["star", Save.data["stars"]]]:
		w.add_child(ArtIcon.new(pair[0], 40))
		w.add_child(UI.label(str(pair[1]) + "  ", 28, UI.INK))
	col.add_child(w)
	col.add_child(UI.label("Day streak: %d" % Game.current_streak(), 22, UI.C_SLATE))
	return card


func _avatar_picker() -> void:
	var dim := UI.full_rect(ColorRect.new())
	dim.color = Color(0.05, 0.03, 0.15, 0.85)
	add_child(dim)
	var c := UI.full_rect(CenterContainer.new())
	dim.add_child(c)
	var card := UI.card(Color.WHITE, 32, 32)
	c.add_child(card)
	var v := UI.vbox(18)
	card.add_child(v)
	v.add_child(UI.label("Choose your hero!", 52, UI.C_PURPLE))
	v.add_child(UI.label("Your hero joins you on every quest.", 26, UI.INK))
	var h := UI.hbox(18)
	v.add_child(h)
	for k in Game.AVATARS:
		h.add_child(UI.avatar_button(k, _pick))
	(h.get_child(0) as Button).grab_focus.call_deferred()


func _pick(kind: String) -> void:
	Save.data["avatar"] = kind
	Save.save_data()
	Game.go("MainMenu")
