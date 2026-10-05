class_name MultiplicationVisualizer
extends Control
## Shows factor_a groups with factor_b objects each and animates them, so a × b can be SEEN.
## Used by every mode: setup() → show_groups() → animate_counting() / highlight_all() / show_solution() → reset().

const CAPTION_H := 100.0
const BADGE := 30.0
const TOTAL_W := 64.0

var a := 0
var b := 0
var kind := "apple"
var groups: Array[Dictionary] = []  # {panel, items, total}
var caption: Label    # "7 groups of 4" / "7 × 4 = 28"
var sum_label: Label  # "4 + 4 + 4 = 12"
var _gen := 0         # bumps on reset/new animation so stale coroutines stop
var _box := UI.box(Color(1, 1, 1, 0.1), 26, 0)
var _group_box := UI.box(Color(1, 1, 1, 0.13), 16, 0)
var _group_lit := UI.box(Color(1, 0.85, 0.25, 0.3), 16, 0)


func _init() -> void:
	_box.border_color = Color(1, 1, 1, 0.25)
	_box.set_border_width_all(2)
	_group_box.border_color = Color(1, 1, 1, 0.3)
	_group_box.set_border_width_all(2)
	_group_lit.border_color = UI.GOLD
	_group_lit.set_border_width_all(3)
	caption = UI.label("", 36, UI.GOLD, 10)
	add_child(caption)
	sum_label = UI.label("", 24, Color.WHITE, 8)
	sum_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(sum_label)
	resized.connect(_layout)


func _draw() -> void:
	draw_style_box(_box, Rect2(Vector2.ZERO, size))


func setup(fa: int, fb: int, object_kind: String) -> void:
	reset()
	a = fa
	b = fb
	kind = object_kind
	for g in a:
		var panel := Panel.new()
		panel.add_theme_stylebox_override("panel", _group_box)
		panel.modulate.a = 0.0
		panel.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(panel)
		panel.add_child(UI.label(str(g + 1), 20, Color(1, 1, 1, 0.75)))
		var items: Array[ArtIcon] = []
		for i in b:
			var it := ArtIcon.new(kind, 8)
			it.scale = Vector2.ZERO
			add_child(it)
			items.append(it)
		var total := UI.label("", 26, UI.GOLD, 8)
		total.modulate.a = 0.0
		add_child(total)
		groups.append({"panel": panel, "items": items, "total": total})
	_layout()


func _layout() -> void:
	caption.position = Vector2(0, size.y - CAPTION_H)
	caption.size = Vector2(size.x, 46)
	sum_label.position = Vector2(12, size.y - CAPTION_H + 44)
	sum_label.size = Vector2(size.x - 24, 50)
	if a == 0:
		return
	var area := Vector2(size.x - 24, size.y - CAPTION_H - 16)
	var cols := 1 if a <= 5 else 2  # groups 1-5 left, 6-10 right
	var rows := ceili(a / float(cols))
	var gw := area.x / cols
	var gh := area.y / rows
	var cell := minf(minf((gw - BADGE - TOTAL_W - 28) / b, gh * 0.8), 60.0)
	for g in a:
		var grp: Dictionary = groups[g]
		var w := BADGE + b * cell + 12
		var x0 := 12 + (g / rows) * gw + (gw - w - TOTAL_W) / 2
		var ph := minf(gh - 6, cell + 14)
		var py := 8 + (g % rows) * gh + (gh - ph) / 2
		var panel: Panel = grp.panel
		panel.position = Vector2(x0, py)
		panel.size = Vector2(w, ph)
		var num: Label = panel.get_child(0)
		num.size = Vector2(BADGE, ph)
		var s := cell * 0.9
		for i in b:
			var it: ArtIcon = grp.items[i]
			it.size = Vector2(s, s)
			it.position = Vector2(x0 + BADGE + i * cell + (cell - s) / 2, py + (ph - s) / 2)
		var total: Label = grp.total
		total.position = Vector2(x0 + w + 4, py)
		total.size = Vector2(TOTAL_W, ph)


func _wait(t: float) -> void:
	if t <= 0.0:
		return
	var tw := create_tween()
	tw.tween_interval(t)
	await tw.finished


## Group by group, objects pop in. Ends with the caption "7 groups of 4".
func show_groups(fast := false) -> void:
	var gen := _gen
	var per_group := 0.0 if fast else clampf(2.4 / a, 0.15, 0.45)
	var step := 0.0 if fast else minf(0.05, per_group * 0.7 / b)
	for g in groups.size():
		if gen != _gen:
			return
		var grp: Dictionary = groups[g]
		create_tween().tween_property(grp.panel, "modulate:a", 1.0, 0.15)
		var items: Array = grp.items
		for i in items.size():
			create_tween().tween_property(items[i], "scale", Vector2.ONE, 0.12 if fast else 0.25) \
				.set_delay(i * step).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if not fast:
			Audio.play("pop", 0.9 + 0.05 * g)
		await _wait(per_group)
	if gen != _gen:
		return
	caption.text = "%d %s of %d" % [a, "group" if a == 1 else "groups", b]
	UI.pop(caption, 0.7)
	for grp in groups:
		var tw := create_tween()
		tw.tween_property(grp.panel, "self_modulate", Color(1.8, 1.8, 1.8), 0.15)
		tw.tween_property(grp.panel, "self_modulate", Color.WHITE, 0.3)


func _make_visible(grp: Dictionary) -> void:
	var panel: Panel = grp.panel
	panel.modulate.a = 1.0
	panel.add_theme_stylebox_override("panel", _group_lit)


## Counts group by group: running totals 4, 8, 12... and "4 + 4 + 4 = 12". Returns false if interrupted.
func animate_counting(step := 0.35) -> bool:
	_gen += 1
	var gen := _gen
	var parts := PackedStringArray()
	for g in groups.size():
		var grp: Dictionary = groups[g]
		_make_visible(grp)
		for it in grp.items:
			var tw := create_tween()
			tw.tween_property(it, "scale", Vector2.ONE * 1.3, 0.08)
			tw.tween_property(it, "scale", Vector2.ONE, 0.18)
		var total: Label = grp.total
		total.text = str((g + 1) * b)
		total.modulate.a = 1.0
		UI.pop(total, 0.4)
		parts.append(str(b))
		sum_label.text = " + ".join(parts) + "  =  %d" % ((g + 1) * b)
		Audio.play("tick", 1.0 + 0.07 * g)
		await _wait(step)
		if gen != _gen:
			return false
	return true


## Every object bounces and sparkles: "all of these together".
func highlight_all() -> void:
	for grp in groups:
		_make_visible(grp)
		var i := 0
		for it in grp.items:
			var tw := create_tween()
			tw.tween_property(it, "scale", Vector2.ONE * 1.35, 0.15).set_delay(i * 0.02)
			tw.tween_property(it, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
			i += 1
	_sparkle()


## Full worked explanation after a mistake: count up, then "7 × 4 = 28".
func show_solution(step := 0.4) -> bool:
	var done: bool = await animate_counting(step)
	if not done:
		return false
	caption.text = "%d × %d = %d" % [a, b, a * b]
	UI.pop(caption, 0.6)
	highlight_all()
	return true


func reset() -> void:
	_gen += 1
	for grp in groups:
		grp.panel.queue_free()
		grp.total.queue_free()
		for it in grp.items:
			it.queue_free()
	groups.clear()
	a = 0
	b = 0
	caption.text = ""
	sum_label.text = ""


func _sparkle() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(size.x / 2, (size.y - CAPTION_H) / 2)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(size.x / 2 - 20, (size.y - CAPTION_H) / 2 - 10)
	p.amount = 60
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 0.7
	p.direction = Vector2(0, -1)
	p.spread = 180
	p.initial_velocity_min = 20
	p.initial_velocity_max = 80
	p.gravity = Vector2(0, -30)
	p.scale_amount_min = 3
	p.scale_amount_max = 7
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 0.85, 1))
	g.set_color(1, Color(1, 0.85, 0.3, 0))
	p.color_ramp = g
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
