class_name UI
## Design system: chunky rounded buttons, cards, labels, bars. Every screen is built from these.

const INK := Color("1d1442")
const GOLD := Color("ffd23f")
const C_ORANGE := Color("ff7a45")
const C_GREEN := Color("22a861")
const C_YELLOW := Color("ffb703")
const C_PURPLE := Color("8e5cf7")
const C_BLUE := Color("1f7ae0")
const C_SLATE := Color("4f5d7e")
const C_PINK := Color("ff4f9a")
const C_KEY := Color("eef2ff")
const PALETTE := [C_ORANGE, C_GREEN, C_BLUE, C_PURPLE, C_PINK]


static func box(color: Color, radius := 24, margin := 16.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	s.anti_aliasing = true
	return s


static func text_color_for(bg: Color) -> Color:
	return INK if bg.get_luminance() > 0.6 else Color.WHITE


static func _btn_box(color: Color, depth: int, radius: int) -> StyleBoxFlat:
	var s := box(color, radius, 10)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.border_width_bottom = depth
	s.border_color = color.darkened(0.35)
	return s


## Applies (or re-applies) the chunky button look in the given color.
static func style_button(b: Button, color: Color, radius := 22) -> void:
	b.add_theme_stylebox_override("normal", _btn_box(color, 7, radius))
	b.add_theme_stylebox_override("hover", _btn_box(color.lightened(0.12), 7, radius))
	b.add_theme_stylebox_override("pressed", _btn_box(color.darkened(0.08), 2, radius))
	b.add_theme_stylebox_override("disabled", _btn_box(color.lerp(Color("6b7080"), 0.75).darkened(0.25), 4, radius))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_corner_radius_all(radius + 4)
	focus.set_border_width_all(4)
	focus.border_color = Color.WHITE
	focus.set_expand_margin_all(5)
	b.add_theme_stylebox_override("focus", focus)
	var fc := text_color_for(color)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, fc)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.8))


static func button(text: String, color: Color, font_size := 30, min_size := Vector2(0, 72), radius := 22) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", font_size)
	style_button(b, color, radius)
	b.pressed.connect(func(): Audio.play("click"))
	return b


## Marks a button as "selected" with a thick border.
static func outline_button(b: Button, color := Color.WHITE) -> void:
	for state in ["normal", "hover"]:
		var s: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
		s.set_border_width_all(5)
		s.border_width_bottom = 8
		s.border_color = color
		b.add_theme_stylebox_override(state, s)


static func label(text: String, font_size := 26, color := Color.WHITE, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", INK)
	return l


static func card(color := Color(1, 1, 1, 0.95), radius := 28, margin := 20.0) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(color, radius, margin)
	s.shadow_color = Color(0, 0, 0, 0.18)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 5)
	p.add_theme_stylebox_override("panel", s)
	return p


static func vbox(sep := 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func bar(color: Color, height := 22.0) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, height)
	p.max_value = 1.0
	p.step = 0.0
	p.add_theme_stylebox_override("background", box(Color(0, 0, 0, 0.2), int(height / 2), 0))
	p.add_theme_stylebox_override("fill", box(color, int(height / 2), 0))
	return p


static func pop(node: Control, from := 0.6) -> void:
	node.pivot_offset = node.size / 2
	node.scale = Vector2.ONE * from
	node.create_tween().tween_property(node, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## Standard screen scaffold: gradient backdrop + padded column. Returns the column.
static func screen(root: Control, top: Color, bottom: Color, deco := "") -> VBoxContainer:
	root.add_child(Backdrop.new(top, bottom, deco))
	var m := MarginContainer.new()
	full_rect(m)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 20 if side in ["top", "bottom"] else 24)
	root.add_child(m)
	var v := vbox(14)
	m.add_child(v)
	return v


static func top_bar(title: String, back_to := "MainMenu") -> HBoxContainer:
	var h := hbox(16)
	var back := button("< MENU" if back_to == "MainMenu" else "< BACK", C_SLATE, 24, Vector2(150, 60))
	back.pressed.connect(Game.go.bind(back_to))
	h.add_child(back)
	var t := label(title, 42, Color.WHITE, 12)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(wallet())
	return h


static func wallet() -> HBoxContainer:
	var h := hbox(6)
	h.add_child(ArtIcon.new("coin", 38))
	h.add_child(label(str(Save.data["coins"]), 28, Color.WHITE, 8))
	h.add_child(ArtIcon.new("star", 38))
	h.add_child(label(str(Save.data["stars"]), 28, Color.WHITE, 8))
	return h


static func avatar_button(kind: String, on_pick: Callable) -> Button:
	var b := button("", C_KEY, 24, Vector2(170, 200))
	var v := vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	full_rect(v)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := ArtIcon.new(kind, 120)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)
	v.add_child(label(Game.AVATAR_NAMES[kind], 26, INK))
	b.add_child(v)
	b.pressed.connect(on_pick.bind(kind))
	return b
