class_name RewardManager
## XP, coins, player levels, stars and combo rules. Pure functions so they are easy to test.

const LEVELS := [
	[0, "Number Explorer"],
	[150, "Multiplication Apprentice"],
	[400, "Table Master"],
	[800, "Math Hero"],
	[1500, "Multiplication Champion"],
]
const XP_CORRECT := 10
const XP_RETRY := 3


static func xp_for_answer(first_try: bool, combo: int) -> int:
	if not first_try:
		return XP_RETRY
	var xp := XP_CORRECT
	if combo >= 3:
		xp += 5
	if combo >= 5:
		xp += 5
	if combo >= 10:
		xp += 10
	return xp


static func coins_for_answer(first_try: bool) -> int:
	return 1 if first_try else 0


static func combo_message(combo: int) -> String:
	if combo >= 10 and combo % 5 == 0:
		return "AMAZING STREAK!"
	if combo == 3 or combo == 5:
		return "COMBO x%d" % combo
	return ""


static func level_index(xp: int) -> int:
	var idx := 0
	for i in LEVELS.size():
		if xp >= LEVELS[i][0]:
			idx = i
	return idx


static func level_name(xp: int) -> String:
	return LEVELS[level_index(xp)][1]


## 0..1 progress toward the next level (1.0 at max level).
static func level_progress(xp: int) -> float:
	var i := level_index(xp)
	if i == LEVELS.size() - 1:
		return 1.0
	var lo: int = LEVELS[i][0]
	var hi: int = LEVELS[i + 1][0]
	return float(xp - lo) / (hi - lo)


static func next_level_xp(xp: int) -> int:
	var i := level_index(xp)
	return -1 if i == LEVELS.size() - 1 else LEVELS[i + 1][0]


## Finishing always earns at least one star: no punishment for mistakes.
static func stars_for(correct: int, total: int) -> int:
	if total <= 0:
		return 0
	var r := float(correct) / total
	if r >= 0.9:
		return 3
	if r >= 0.6:
		return 2
	return 1
