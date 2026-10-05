extends Node
## SaveManager: local persistence with ConfigFile.
## On Web, user:// is backed by the browser's IndexedDB, so progress survives a refresh.

signal saved

var path := "user://multiply_quest.cfg"
var data: Dictionary = {}


static func defaults() -> Dictionary:
	return {
		"version": 1,
		"avatar": "",
		"xp": 0,
		"coins": 0,
		"stars": 0,
		"best_combo": 0,
		"best_speed": 0,
		"day_streak": 0,
		"last_day": "",
		"daily": {},      # "YYYY-MM-DD" -> stars earned
		"adventure": {},  # "world_level" -> best stars
		"facts": {},      # "3x7" -> {m, attempts, correct, wrong, ms}
		"stats": {"answered": 0, "correct": 0, "ms": 0},
		"history": {},    # "YYYY-MM-DD" -> [answered, correct]; groundwork for a parent dashboard
		"settings": {"music": true, "sfx": true},
	}


func _ready() -> void:
	load_data()


func load_data() -> void:
	data = defaults()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	var loaded = cfg.get_value("game", "data", {})
	if not loaded is Dictionary:
		return
	for k in loaded:
		if data.has(k) and data[k] is Dictionary and loaded[k] is Dictionary and k == "settings":
			data[k].merge(loaded[k], true)  # keeps settings added in later versions
		else:
			data[k] = loaded[k]


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "data", data)
	cfg.save(path)
	saved.emit()


func reset() -> void:
	data = defaults()
	save_data()
