class_name Backdrop
extends Control
## Full-screen gradient background with a few slowly drifting, faint objects.

var top: Color
var bottom: Color
var decor: Array = []  # [icon, relative position, phase]
var t := 0.0


func _init(c_top := Color("2a1b6e"), c_bottom := Color("c2448b"), deco := "") -> void:
	top = c_top
	bottom = c_bottom
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if deco == "":
		return
	var r := RandomNumberGenerator.new()
	r.seed = 7
	var kinds := deco.split(",")
	for i in 12:
		var ic := ArtIcon.new(kinds[i % kinds.size()], r.randf_range(36, 84))
		ic.modulate.a = 0.15
		ic.rotation = r.randf_range(-0.5, 0.5)
		add_child(ic)
		decor.append([ic, Vector2(r.randf(), r.randf()), r.randf() * TAU])


func _process(delta: float) -> void:
	t += delta
	for d in decor:
		var ic: ArtIcon = d[0]
		ic.position = d[1] * size + Vector2(0, sin(t * 0.6 + d[2]) * 14) - ic.size / 2


func _draw() -> void:
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	draw_circle(Vector2(size.x * 0.85, size.y * 0.15), size.y * 0.35, Color(1, 1, 1, 0.05))
	draw_circle(Vector2(size.x * 0.1, size.y * 0.9), size.y * 0.4, Color(1, 1, 1, 0.04))
