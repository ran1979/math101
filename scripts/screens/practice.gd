extends Control
## Pick a times table (or mix everything). No timer.


func _ready() -> void:
	var v := UI.screen(self, Color("0f3d2e"), Color("22a861"), "apple,star")
	v.add_child(UI.top_bar("PRACTICE"))
	v.add_child(UI.label("Pick a table to practice. No timer, take your time!", 28, Color.WHITE, 8))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)
	var first: Button = null
	for t in range(1, 11):
		var cell := UI.vbox(4)
		cell.size_flags_horizontal = SIZE_EXPAND_FILL
		var b := UI.button("×%d" % t, UI.PALETTE[t % UI.PALETTE.size()], 48, Vector2(0, 110))
		b.pressed.connect(Game.start.bind("practice", {"table": t}))
		cell.add_child(b)
		cell.add_child(UI.label("%d / 10 mastered" % Game.table_mastered_count(t), 22, Color.WHITE, 6))
		grid.add_child(cell)
		if first == null:
			first = b
	var mix := UI.button("MIX EVERYTHING", UI.C_YELLOW, 36, Vector2(0, 90))
	mix.pressed.connect(Game.start.bind("practice", {"table": 0}))
	v.add_child(mix)
	v.add_child(UI.label("Mix focuses on the facts you find tricky.", 22, Color.WHITE, 6))
	first.grab_focus.call_deferred()
