extends Node
## AudioManager: every sound is synthesized at startup, so the game ships with no audio files.
## To use real assets, put AudioStreams into `sounds` under the same names.

const RATE := 22050

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer


func _ready() -> void:
	sounds = {
		"click": _notes([[660, 0.05]], 0.2),
		"pop": _notes([[880, 0.05]], 0.12),
		"tick": _notes([[740, 0.08]], 0.22),
		"correct": _notes([[523, 0.08], [659, 0.08], [784, 0.22]], 0.32),
		"try": _notes([[440, 0.12], [392, 0.22]], 0.25),  # soft, never a buzzer
		"coin": _notes([[988, 0.06], [1319, 0.18]], 0.2),
		"level": _notes([[523, 0.1], [659, 0.1], [784, 0.1], [1047, 0.4]], 0.32),
		"celebrate": _notes([[784, 0.07], [988, 0.07], [1175, 0.07], [1568, 0.32]], 0.3),
	}
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music = AudioStreamPlayer.new()
	music.volume_db = -16.0
	music.stream = _music()
	add_child(music)
	apply_settings()


func play(sound: String, pitch := 1.0) -> void:
	if not Save.data["settings"]["sfx"] or not sounds.has(sound):
		return
	for p in players:
		if not p.playing:
			p.stream = sounds[sound]
			p.pitch_scale = pitch
			p.play()
			return


func apply_settings() -> void:
	if Save.data["settings"]["music"]:
		if not music.playing:
			music.play()
	else:
		music.stop()


static func _env(i: int, n: int) -> float:
	return minf(1.0, i / (0.006 * RATE)) * pow(1.0 - float(i) / n, 1.5)


func _notes(notes: Array, vol: float) -> AudioStreamWAV:
	var pcm := PackedFloat32Array()
	for nt in notes:
		var f: float = nt[0]
		var n := int(nt[1] * RATE)
		for i in n:
			var t := float(i) / RATE
			pcm.append((sin(TAU * f * t) + 0.25 * sin(TAU * 2.0 * f * t)) * _env(i, n) * vol)
	return _wav(pcm)


## 8-second cheerful loop (melody + bass), synthesized once.
func _music() -> AudioStreamWAV:
	var beat := 0.25
	var melody := [523, 659, 784, 659, 880, 784, 659, 784, 698, 880, 1047, 880, 784, 659, 587, 659,
		523, 659, 784, 1047, 880, 784, 659, 523, 587, 659, 698, 784, 659, 587, 523, 0]
	var bass := [131, 110, 87, 98]  # C A F G, one per 8 beats
	var n_beat := int(beat * RATE)
	var pcm := PackedFloat32Array()
	pcm.resize(n_beat * melody.size())
	for k in melody.size():
		var f: float = melody[k]
		var bf: float = bass[k / 8]
		for i in n_beat:
			var t := float(i) / RATE
			var e := _env(i, n_beat)
			var s := 0.2 * sin(TAU * bf * t) * e
			if f > 0:
				s += 0.16 * sin(TAU * f * t) * e
			pcm[k * n_beat + i] = s
	var w := _wav(pcm)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = pcm.size()
	return w


func _wav(pcm: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(pcm.size() * 2)
	for i in pcm.size():
		bytes.encode_s16(i * 2, int(clampf(pcm[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	return w
