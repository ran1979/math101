extends Node
## GameManager: worlds, sessions, scene changes, reward bookkeeping and the global UI theme.

signal level_up(level_name: String)

const AVATARS := ["cat", "dog", "robot", "dragon"]
const AVATAR_NAMES := {"cat": "Cat", "dog": "Dog", "robot": "Robot", "dragon": "Dragon"}

const WORLDS := [
	{"name": "Number Forest", "object": "apple", "noun": "apples", "a": [1, 3], "b": [1, 5],
		"top": Color("1b5e3b"), "bottom": Color("3fa35b"), "accent": Color("2fbf71")},
	{"name": "Pirate Island", "object": "coin", "noun": "coins", "a": [4, 6], "b": [1, 7],
		"top": Color("0b3f73"), "bottom": Color("1a9fb3"), "accent": Color("1f8fff")},
	{"name": "Space Station", "object": "star", "noun": "stars", "a": [6, 8], "b": [3, 8],
		"top": Color("0d0b2e"), "bottom": Color("3b1f6e"), "accent": Color("8e5cf7")},
	{"name": "Dragon Castle", "object": "gem", "noun": "gems", "a": [8, 10], "b": [5, 10],
		"top": Color("3a0d4a"), "bottom": Color("8a2c5a"), "accent": Color("e5484d")},
]
const LEVELS_PER_WORLD := 5  # 4 levels + boss
const LEVEL_NAMES := ["Level 1", "Level 2", "Level 3", "Level 4", "Boss Challenge"]
const LEVEL_QUESTIONS := 6
const BOSS_QUESTIONS := 10

var session: Dictionary = {}
var last_world := 0


func _ready() -> void:
	sync_data()
	_apply_theme()
	for w in WORLDS.size():
		if level_unlocked(w, 0):
			last_world = w


func sync_data() -> void:
	Questions.facts = Save.data["facts"]


func _apply_theme() -> void:
	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 0.5
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = 26
	t.set_stylebox("panel", "TooltipPanel", UI.box(UI.INK, 10, 8))
	get_tree().root.theme = t


# --- navigation -------------------------------------------------------------

func go(screen: String) -> void:
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % screen)


func start(mode: String, opts := {}) -> void:
	session = opts.duplicate()
	session["mode"] = mode
	if mode == "adventure":
		last_world = session.get("world", 0)
	go("Quiz")


# --- worlds -----------------------------------------------------------------

## Each level widens the range of group sizes; the boss uses the whole world.
func world_pool(w: int, level: int) -> Array:
	var W: Dictionary = WORLDS[w]
	var b_hi: int = W.b[1]
	if level < LEVELS_PER_WORLD - 1:
		b_hi = W.b[0] + ceili((W.b[1] - W.b[0]) * (level + 1) / 4.0)
	return Questions.pairs_in_range(W.a[0], W.a[1], W.b[0], b_hi)


func world_for_table(t: int) -> int:
	if t <= 0:
		return randi() % WORLDS.size()
	if t <= 3:
		return 0
	if t <= 5:
		return 1
	return 2 if t <= 8 else 3


func level_stars(w: int, l: int) -> int:
	return int(Save.data["adventure"].get("%d_%d" % [w, l], 0))


func level_unlocked(w: int, l: int) -> bool:
	if l > 0:
		return level_stars(w, l - 1) > 0
	if w > 0:
		return level_stars(w - 1, LEVELS_PER_WORLD - 1) > 0
	return true


func complete_level(w: int, l: int, stars: int) -> void:
	var prev := level_stars(w, l)
	if stars > prev:
		Save.data["adventure"]["%d_%d" % [w, l]] = stars
		add_stars(stars - prev)


func daily_stars() -> int:
	return int(Save.data["daily"].get(today(), 0))


func complete_daily(stars: int) -> void:
	Save.data["daily"][today()] = stars
	add_stars(stars)


func table_mastered_count(t: int) -> int:
	var n := 0
	for i in range(1, 11):
		if Questions.get_mastery(i, t) >= Questions.MAX_MASTERY:
			n += 1
	return n


func tables_mastered() -> int:
	var n := 0
	for t in range(1, 11):
		if table_mastered_count(t) == 10:
			n += 1
	return n


# --- rewards & stats --------------------------------------------------------

## Records the answer (first attempts only count toward mastery) and grants rewards.
func answer(q: Dictionary, correct: bool, first_try: bool, ms: int, combo: int) -> Dictionary:
	var gained := {"xp": 0, "coins": 0}
	if first_try:
		Questions.record_answer(q.factor_a, q.factor_b, correct, ms)
		var st: Dictionary = Save.data["stats"]
		st["answered"] += 1
		st["correct"] += int(correct)
		st["ms"] += ms
		var day: Array = Save.data["history"].get(today(), [0, 0])
		day[0] += 1
		day[1] += int(correct)
		Save.data["history"][today()] = day
		_touch_day()
	if correct:
		gained.xp = RewardManager.xp_for_answer(first_try, combo)
		gained.coins = RewardManager.coins_for_answer(first_try)
		add_coins(gained.coins)
		add_xp(gained.xp)
	Save.data["best_combo"] = maxi(Save.data["best_combo"], combo)
	Save.save_data()
	return gained


func add_xp(n: int) -> void:
	var before := RewardManager.level_index(Save.data["xp"])
	Save.data["xp"] += n
	if RewardManager.level_index(Save.data["xp"]) > before:
		level_up.emit(RewardManager.level_name(Save.data["xp"]))


func add_coins(n: int) -> void:
	Save.data["coins"] += n


func add_stars(n: int) -> void:
	Save.data["stars"] += n


func today() -> String:
	return Time.get_date_string_from_system()


func _yesterday() -> String:
	var now := Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	return Time.get_date_string_from_unix_time(now - 86400)


func _touch_day() -> void:
	var t := today()
	if Save.data["last_day"] == t:
		return
	Save.data["day_streak"] = Save.data["day_streak"] + 1 if Save.data["last_day"] == _yesterday() else 1
	Save.data["last_day"] = t


func current_streak() -> int:
	return Save.data["day_streak"] if Save.data["last_day"] in [today(), _yesterday()] else 0


func avatar() -> String:
	return Save.data["avatar"] if Save.data["avatar"] != "" else "cat"
