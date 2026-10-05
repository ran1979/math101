class_name ArtIcon
extends Control
## A Control that draws one piece of procedural Art (object, avatar, star...).

var kind := "apple"


func _init(k := "apple", px := 48.0) -> void:
	kind = k
	custom_minimum_size = Vector2(px, px)
	size = custom_minimum_size
	pivot_offset = size / 2
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(func(): pivot_offset = size / 2)


func set_kind(k: String) -> void:
	kind = k
	queue_redraw()


func _draw() -> void:
	Art.draw(self, kind, size / 2, minf(size.x, size.y) / 2)
