extends Control

var reset_armed := false


func _ready() -> void:
	var v := UI.screen(self, Color("1d2440"), Color("4f5d7e"))
	v.add_child(UI.top_bar("SETTINGS"))
	var center := CenterContainer.new()
	center.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(center)
	var card := UI.card(Color.WHITE, 32, 28)
	center.add_child(card)
	var col := UI.vbox(16)
	card.add_child(col)
	var row := UI.hbox(16)
	col.add_child(row)
	var music := _toggle("MUSIC", "music")
	row.add_child(music)
	row.add_child(_toggle("SOUND EFFECTS", "sfx"))
	col.add_child(UI.label("Your hero", 30, UI.INK))
	var heroes := UI.hbox(14)
	col.add_child(heroes)
	for k in Game.AVATARS:
		var b := UI.avatar_button(k, _pick_avatar)
		if k == Save.data["avatar"]:
			UI.outline_button(b, UI.C_GREEN)
		heroes.add_child(b)
	var reset := UI.button("RESET ALL PROGRESS", Color("d93f44"), 24, Vector2(0, 62))
	reset.pressed.connect(_reset.bind(reset))
	col.add_child(reset)
	music.grab_focus.call_deferred()


func _toggle(title: String, key: String) -> Button:
	var b := UI.button("", UI.C_GREEN, 28, Vector2(300, 80))
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	_paint(b, title, key)
	b.pressed.connect(func():
		Save.data["settings"][key] = not Save.data["settings"][key]
		Save.save_data()
		Audio.apply_settings()
		_paint(b, title, key)
	)
	return b


func _paint(b: Button, title: String, key: String) -> void:
	var on: bool = Save.data["settings"][key]
	b.text = "%s: %s" % [title, "ON" if on else "OFF"]
	UI.style_button(b, UI.C_GREEN if on else UI.C_SLATE)


func _pick_avatar(kind: String) -> void:
	Save.data["avatar"] = kind
	Save.save_data()
	Game.go("Settings")


## Two taps needed, so progress is never erased by accident.
func _reset(b: Button) -> void:
	if not reset_armed:
		reset_armed = true
		b.text = "TAP AGAIN TO ERASE EVERYTHING"
		return
	Save.reset()
	Game.sync_data()
	Audio.apply_settings()
	Game.go("MainMenu")
