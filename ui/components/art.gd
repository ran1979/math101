class_name Art
## Procedural 2D art. Objects, avatars and icons are drawn from shapes, so the game needs no image files.
## kind: apple, coin, star, gem | cat, dog, robot, dragon | star_on, star_off, lock

const INK := Color("2b2340")


static func draw(ci: CanvasItem, kind: String, c: Vector2, r: float) -> void:
	match kind:
		"apple": _apple(ci, c, r)
		"coin": _coin(ci, c, r)
		"star", "star_on": _star(ci, c, r)
		"star_off": _star_off(ci, c, r)
		"gem": _gem(ci, c, r)
		"cat": _cat(ci, c, r)
		"dog": _dog(ci, c, r)
		"robot": _robot(ci, c, r)
		"dragon": _dragon(ci, c, r)
		"lock": _lock(ci, c, r)
		_: ci.draw_circle(c, r * 0.8, Color.WHITE)


static func ellipse(c: Vector2, rx: float, ry: float, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


## Points given in units of r around c; mirror flips x.
static func poly(c: Vector2, r: float, pts: Array, mirror := false) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + Vector2(-p[0] if mirror else p[0], p[1]) * r)
	return out


static func star_points(c: Vector2, ro: float, ri: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + PI * i / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (ro if i % 2 == 0 else ri))
	return pts


static func outline(ci: CanvasItem, pts: PackedVector2Array, color: Color, width: float) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, color, width, true)


static func _eyes(ci: CanvasItem, c: Vector2, r: float, dx: float, y: float) -> void:
	for m in [-1.0, 1.0]:
		var e: Vector2 = c + Vector2(dx * m, y) * r
		ci.draw_circle(e, r * 0.11, INK)
		ci.draw_circle(e + Vector2(0.035, -0.04) * r, r * 0.04, Color.WHITE)


# --- objects ---------------------------------------------------------------

static func _apple(ci: CanvasItem, c: Vector2, r: float) -> void:
	var red := Color("e8383d")
	ci.draw_line(c + Vector2(0, -0.45) * r, c + Vector2(0.12, -0.92) * r, Color("6b3e1f"), r * 0.14)
	ci.draw_colored_polygon(ellipse(c + Vector2(0.34, -0.72) * r, r * 0.3, r * 0.13, -0.5), Color("43b649"))
	ci.draw_circle(c + Vector2(-0.27, 0.08) * r, r * 0.58, red)
	ci.draw_circle(c + Vector2(0.27, 0.08) * r, r * 0.58, red)
	ci.draw_circle(c + Vector2(0, 0.22) * r, r * 0.55, red)
	ci.draw_colored_polygon(ellipse(c + Vector2(-0.38, -0.1) * r, r * 0.12, r * 0.2, 0.4), Color(1, 1, 1, 0.55))


static func _coin(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r * 0.92, Color("c98a0b"))
	ci.draw_circle(c, r * 0.8, Color("ffcb2f"))
	ci.draw_circle(c, r * 0.58, Color("f5b014"))
	ci.draw_colored_polygon(star_points(c, r * 0.4, r * 0.17), Color("fff1a8"))
	ci.draw_arc(c, r * 0.68, -2.6, -1.6, 8, Color(1, 1, 1, 0.7), r * 0.08)


static func _star(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := star_points(c + Vector2(0, 0.05) * r, r * 0.98, r * 0.44)
	ci.draw_colored_polygon(pts, Color("ffd23f"))
	outline(ci, pts, Color("f08c00"), maxf(1.0, r * 0.1))
	ci.draw_circle(c + Vector2(-0.18, -0.12) * r, r * 0.1, Color(1, 1, 1, 0.75))


static func _star_off(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := star_points(c + Vector2(0, 0.05) * r, r * 0.98, r * 0.44)
	ci.draw_colored_polygon(pts, Color(0, 0, 0, 0.22))
	outline(ci, pts, Color(1, 1, 1, 0.75), maxf(1.0, r * 0.09))


static func _gem(ci: CanvasItem, c: Vector2, r: float) -> void:
	var body := poly(c, r, [[-0.55, -0.6], [0.55, -0.6], [0.95, -0.15], [0, 0.95], [-0.95, -0.15]])
	ci.draw_colored_polygon(body, Color("9b5cff"))
	ci.draw_colored_polygon(poly(c, r, [[-0.55, -0.6], [0.55, -0.6], [0.95, -0.15], [-0.95, -0.15]]), Color("c79bff"))
	ci.draw_colored_polygon(poly(c, r, [[-0.3, -0.6], [0.3, -0.6], [0.45, -0.15], [-0.45, -0.15]]), Color("e9d8ff"))
	ci.draw_colored_polygon(poly(c, r, [[-0.45, -0.15], [0.45, -0.15], [0, 0.95]]), Color("7f3df0"))
	outline(ci, body, Color("4b1d9e"), maxf(1.0, r * 0.08))


static func _lock(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_arc(c + Vector2(0, -0.2) * r, r * 0.36, PI, TAU, 16, Color("dfe4f0"), r * 0.15)
	ci.draw_rect(Rect2(c + Vector2(-0.55, -0.22) * r, Vector2(1.1, 0.95) * r), Color("ffd23f"))
	ci.draw_circle(c + Vector2(0, 0.18) * r, r * 0.12, INK)
	ci.draw_rect(Rect2(c + Vector2(-0.05, 0.2) * r, Vector2(0.1, 0.3) * r), INK)


# --- avatars ---------------------------------------------------------------

static func _cat(ci: CanvasItem, c: Vector2, r: float) -> void:
	var fur := Color("ff9f43")
	var pink := Color("ff8fbf")
	for m in [false, true]:
		ci.draw_colored_polygon(poly(c, r, [[-0.8, -0.1], [-0.62, -0.95], [-0.15, -0.6]], m), fur)
		ci.draw_colored_polygon(poly(c, r, [[-0.66, -0.3], [-0.6, -0.75], [-0.32, -0.56]], m), pink)
	ci.draw_circle(c + Vector2(0, 0.12) * r, r * 0.72, fur)
	for x in [-0.12, 0.0, 0.12]:
		ci.draw_line(c + Vector2(x, -0.58) * r, c + Vector2(x, -0.4) * r, fur.darkened(0.25), r * 0.06)
	_eyes(ci, c, r, 0.28, 0.02)
	ci.draw_colored_polygon(poly(c, r, [[-0.09, 0.22], [0.09, 0.22], [0, 0.32]]), pink)
	for m in [-1.0, 1.0]:
		ci.draw_arc(c + Vector2(0.08 * m, 0.33) * r, r * 0.08, 0, PI, 8, INK, r * 0.04)
		for y in [0.24, 0.4]:
			ci.draw_line(c + Vector2(0.34 * m, 0.3) * r, c + Vector2(0.92 * m, y) * r, Color(INK, 0.5), r * 0.03)


static func _dog(ci: CanvasItem, c: Vector2, r: float) -> void:
	var fur := Color("c98b5a")
	var ear := Color("7a4a2a")
	ci.draw_colored_polygon(ellipse(c + Vector2(-0.68, 0.05) * r, r * 0.22, r * 0.48, 0.35), ear)
	ci.draw_colored_polygon(ellipse(c + Vector2(0.68, 0.05) * r, r * 0.22, r * 0.48, -0.35), ear)
	ci.draw_circle(c + Vector2(0, 0.05) * r, r * 0.68, fur)
	ci.draw_circle(c + Vector2(0.28, -0.07) * r, r * 0.2, ear)
	ci.draw_colored_polygon(ellipse(c + Vector2(0, 0.62) * r, r * 0.11, r * 0.14), Color("ff6b8b"))
	ci.draw_colored_polygon(ellipse(c + Vector2(0, 0.36) * r, r * 0.38, r * 0.27), Color("f3dcc2"))
	_eyes(ci, c, r, 0.28, -0.07)
	ci.draw_colored_polygon(ellipse(c + Vector2(0, 0.24) * r, r * 0.13, r * 0.09), INK)
	ci.draw_line(c + Vector2(0, 0.3) * r, c + Vector2(0, 0.46) * r, INK, r * 0.04)


static func _robot(ci: CanvasItem, c: Vector2, r: float) -> void:
	var dark := Color("2b3a55")
	var cyan := Color("39e1ff")
	ci.draw_line(c + Vector2(0, -0.6) * r, c + Vector2(0, -0.88) * r, dark, r * 0.08)
	ci.draw_circle(c + Vector2(0, -0.9) * r, r * 0.12, Color("ff4f6d"))
	ci.draw_rect(Rect2(c + Vector2(-0.92, -0.18) * r, Vector2(0.22, 0.4) * r), dark)
	ci.draw_rect(Rect2(c + Vector2(0.7, -0.18) * r, Vector2(0.22, 0.4) * r), dark)
	var head := StyleBoxFlat.new()
	head.bg_color = Color("a9bccf")
	head.set_corner_radius_all(int(r * 0.25))
	head.set_border_width_all(int(maxf(1.0, r * 0.06)))
	head.border_color = dark
	ci.draw_style_box(head, Rect2(c + Vector2(-0.75, -0.62) * r, Vector2(1.5, 1.3) * r))
	for m in [-1.0, 1.0]:
		ci.draw_circle(c + Vector2(0.3 * m, -0.12) * r, r * 0.18, dark)
		ci.draw_circle(c + Vector2(0.3 * m, -0.12) * r, r * 0.11, cyan)
	ci.draw_rect(Rect2(c + Vector2(-0.38, 0.24) * r, Vector2(0.76, 0.2) * r), dark)
	for x in [-0.19, 0.0, 0.19]:
		ci.draw_line(c + Vector2(x, 0.26) * r, c + Vector2(x, 0.42) * r, cyan, r * 0.04)


static func _dragon(ci: CanvasItem, c: Vector2, r: float) -> void:
	var scale_c := Color("43c46a")
	for m in [false, true]:
		ci.draw_colored_polygon(poly(c, r, [[-0.52, -0.42], [-0.66, -1.0], [-0.22, -0.58]], m), Color("ffd23f"))
	ci.draw_colored_polygon(poly(c, r, [[-0.12, -0.6], [0, -0.88], [0.12, -0.6]]), Color("2e9e52"))
	ci.draw_circle(c + Vector2(0, 0.05) * r, r * 0.7, scale_c)
	ci.draw_colored_polygon(ellipse(c + Vector2(0, 0.38) * r, r * 0.45, r * 0.28), Color("b8f28a"))
	for m in [-1.0, 1.0]:
		ci.draw_circle(c + Vector2(0.14 * m, 0.3) * r, r * 0.05, INK)
		ci.draw_colored_polygon(ellipse(c + Vector2(0.3 * m, -0.14) * r, r * 0.16, r * 0.14), Color("fff07a"))
		ci.draw_colored_polygon(ellipse(c + Vector2(0.3 * m, -0.14) * r, r * 0.04, r * 0.12), INK)
	ci.draw_arc(c + Vector2(0, 0.36) * r, r * 0.22, 0.35, PI - 0.35, 12, INK, r * 0.045)
