class_name Keypad
extends VBoxContainer
## Big on-screen number pad: 1-9, 0, ERASE, ANSWER.

signal digit(d: int)
signal erase
signal submit

var buttons: Array[Button] = []


func _init() -> void:
	add_theme_constant_override("separation", 8)
	for row in [[1, 2, 3], [4, 5, 6], [7, 8, 9], [0, -1]]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.size_flags_vertical = SIZE_EXPAND_FILL
		add_child(h)
		for d in row:
			var b := UI.button(str(d) if d >= 0 else "ERASE", UI.C_KEY if d >= 0 else UI.C_SLATE,
				36 if d >= 0 else 24, Vector2(0, 54))
			if d >= 0:
				b.pressed.connect(func(): digit.emit(d))
			else:
				b.pressed.connect(func(): erase.emit())
			h.add_child(b)
			buttons.append(b)
	var ok := UI.button("ANSWER", UI.C_GREEN, 32, Vector2(0, 64))
	ok.pressed.connect(func(): submit.emit())
	add_child(ok)
	buttons.append(ok)
	for b in buttons:
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.size_flags_vertical = SIZE_EXPAND_FILL
		b.focus_mode = FOCUS_NONE  # Enter is handled by the screen, not a focused key


func set_enabled(on: bool) -> void:
	for b in buttons:
		b.disabled = not on
