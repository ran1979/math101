extends Control
## Adventure map: 4 worlds, each 4 levels + a boss. Finishing a level unlocks the next.

const NODE_POS := [Vector2(0.1, 0.66), Vector2(0.3, 0.3), Vector2(0.5, 0.66), Vector2(0.7, 0.3), Vector2(0.89, 0.5)]

var world := 0
var map: Control
var nodes: Array[Control] = []


func _ready() -> void:
	world = Game.last_world
	var W: Dictionary = Game.WORLDS[world]
	var v := UI.screen(self, W.top, W.bottom, W.object)
	v.add_child(UI.top_bar("ADVENTURE"))

	var tabs := UI.hbox(12)
	v.add_child(tabs)
	for i in Game.WORLDS.size():
		var open := Game.level_unlocked(i, 0)
		var b := UI.button(Game.WORLDS[i].name if open else "LOCKED", Game.WORLDS[i].accent, 24, Vector2(0, 60))
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.disabled = not open
		if i == world:
			UI.outline_button(b)
		b.pressed.connect(_pick_world.bind(i))
		tabs.add_child(b)
	v.add_child(UI.label("%s: from %d×%d up to %d×%d. Collect the %s!" % [
		W.name, W.a[0], W.b[0], W.a[1], W.b[1], W.noun], 26, Color.WHITE, 8))

	map = Control.new()
	map.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(map)
	map.draw.connect(_draw_path)
	map.resized.connect(_layout)
	var focus: Button = null
	for l in Game.LEVELS_PER_WORLD:
		var boss := l == Game.LEVELS_PER_WORLD - 1
		var open := Game.level_unlocked(world, l)
		var d := 140.0 if boss else 110.0
		var holder := UI.vbox(4)
		var b := UI.button(("BOSS" if boss else str(l + 1)) if open else "",
			UI.C_PINK if boss else UI.C_ORANGE, 32 if boss else 44, Vector2(d, d), int(d / 2))
		b.size_flags_horizontal = SIZE_SHRINK_CENTER
		b.disabled = not open
		if not open:
			var lock := ArtIcon.new("lock", d * 0.5)
			lock.position = Vector2(d * 0.25, d * 0.2)
			b.add_child(lock)
		else:
			focus = b
		b.pressed.connect(Game.start.bind("adventure", {"world": world, "level": l}))
		holder.add_child(b)
		holder.add_child(UI.label(Game.LEVEL_NAMES[l], 22, Color.WHITE, 6))
		var stars := UI.hbox(2)
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		for s in 3:
			stars.add_child(ArtIcon.new("star_on" if s < Game.level_stars(world, l) else "star_off", 28))
		holder.add_child(stars)
		map.add_child(holder)
		nodes.append(holder)
	if focus:
		focus.grab_focus.call_deferred()


func _pick_world(i: int) -> void:
	Game.last_world = i
	Game.go("Adventure")


func _layout() -> void:
	for i in nodes.size():
		var n := nodes[i]
		n.size = n.get_combined_minimum_size()
		n.position = NODE_POS[i] * map.size - Vector2(n.size.x / 2, n.size.y * 0.35)
	map.queue_redraw()


func _draw_path() -> void:
	for i in nodes.size() - 1:
		map.draw_dashed_line(NODE_POS[i] * map.size, NODE_POS[i + 1] * map.size, Color(1, 1, 1, 0.55), 8.0, 18.0)
