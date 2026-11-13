extends Node
## ระบบเสียงของเกม (autoload ชื่อ Sound): สร้างเสียงดนตรี (BGM) และเอฟเฟกต์ (SFX) แบบสังเคราะห์ในโค้ด
## รองรับการ export ลงเว็บ (Web Audio) โดยไม่ต้องใช้ไฟล์เสียงภายนอก

const SAMPLE_RATE := 22050
const SFX_POOL_SIZE := 10

var muted := false
var bgm_volume_db := -10.0
var sfx_volume_db := -6.0

var _bgm_player: AudioStreamPlayer
var _bgm_tween: Tween
var _current_bgm := ""
var _bgm_cache := {}   # ชื่อฉาก -> AudioStreamWAV
var _sfx_cache := {}   # ชื่อเสียง -> AudioStreamWAV
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20261113
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = bgm_volume_db
	add_child(_bgm_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = sfx_volume_db
		add_child(p)
		_sfx_pool.append(p)

	_build_all_sfx()


func set_muted(value: bool) -> void:
	muted = value
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_mute(bus, muted)


func toggle_mute() -> bool:
	set_muted(not muted)
	return muted


## เล่นเสียงเอฟเฟกต์ (pitch_jitter > 0 จะสุ่มระดับเสียงเล็กน้อยไม่ให้ซ้ำซาก)
func play(sfx_name: String, pitch_jitter := 0.0, vol_offset_db := 0.0) -> void:
	if muted or not _sfx_cache.has(sfx_name):
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	p.stream = _sfx_cache[sfx_name]
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 1.0
	p.volume_db = sfx_volume_db + vol_offset_db
	p.play()


## เล่นเพลงประกอบตามแผนที่ (fade สลับเพลงอย่างนุ่มนวล)
func play_bgm(stage_id: String) -> void:
	if stage_id == _current_bgm and _bgm_player.playing:
		return
	_current_bgm = stage_id
	if stage_id == "":
		_fade_out_bgm()
		return
	if not _bgm_cache.has(stage_id):
		_bgm_cache[stage_id] = _build_bgm(stage_id)
	var next_stream: AudioStreamWAV = _bgm_cache[stage_id]
	if _bgm_tween:
		_bgm_tween.kill()
	if _bgm_player.playing:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", -40.0, 0.25)
		_bgm_tween.tween_callback(func() -> void:
			_bgm_player.stream = next_stream
			_bgm_player.play()
		)
		_bgm_tween.tween_property(_bgm_player, "volume_db", bgm_volume_db, 0.35)
	else:
		_bgm_player.stream = next_stream
		_bgm_player.volume_db = -30.0
		_bgm_player.play()
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", bgm_volume_db, 0.4)


func _fade_out_bgm() -> void:
	if _bgm_tween:
		_bgm_tween.kill()
	if _bgm_player.playing:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", -40.0, 0.3)
		_bgm_tween.tween_callback(_bgm_player.stop)


# ---------- สร้างไฟล์เสียง WAV ในหน่วยความจำ ----------

func _make_wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var n := samples.size()
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var s := clampf(samples[i], -0.98, 0.98)
		data.encode_s16(i * 2, int(s * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = n
	return wav


func _midi_to_hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


func _build_all_sfx() -> void:
	_sfx_cache["jump"] = _sfx_sweep(240.0, 540.0, 0.11, 0.35, "tri")
	_sfx_cache["land"] = _sfx_sweep(120.0, 50.0, 0.08, 0.28, "sine")
	_sfx_cache["slash"] = _sfx_whoosh(0.14, 900.0, 260.0, 0.38)
	_sfx_cache["claw"] = _sfx_whoosh(0.16, 1300.0, 320.0, 0.42)
	_sfx_cache["hit"] = _sfx_impact(0.12, 190.0, 60.0, 0.48)
	_sfx_cache["heavy_hit"] = _sfx_impact(0.20, 145.0, 42.0, 0.62)
	_sfx_cache["dash"] = _sfx_whoosh(0.22, 600.0, 1200.0, 0.36)
	_sfx_cache["spin"] = _sfx_spin(0.34)
	_sfx_cache["roar"] = _sfx_roar(0.55)
	_sfx_cache["hurt"] = _sfx_hurt(0.18)
	_sfx_cache["enemy_die"] = _sfx_notes([76, 72, 67], 0.06, 0.35, "tri")
	_sfx_cache["boss_die"] = _sfx_boss_die()
	_sfx_cache["coin"] = _sfx_notes([88, 95], 0.075, 0.32, "sine")
	_sfx_cache["item"] = _sfx_notes([84, 91], 0.09, 0.32, "tri")
	_sfx_cache["potion"] = _sfx_notes([72, 76, 79, 84], 0.075, 0.35, "sine")
	_sfx_cache["level_up"] = _sfx_notes([72, 76, 79, 84, 88], 0.10, 0.42, "warm")
	_sfx_cache["transform"] = _sfx_transform()
	_sfx_cache["portal"] = _sfx_notes([67, 74, 79, 86], 0.085, 0.32, "sine")
	_sfx_cache["talk"] = _sfx_sweep(560.0, 620.0, 0.04, 0.18, "sine")
	_sfx_cache["ui"] = _sfx_sweep(420.0, 480.0, 0.04, 0.20, "tri")
	_sfx_cache["quest"] = _sfx_notes([79, 83, 86], 0.10, 0.34, "warm")


func _wave(phase: float, kind: String) -> float:
	var p := phase - floorf(phase)
	match kind:
		"sine":
			return sin(p * TAU)
		"tri":
			return 1.0 - 4.0 * absf(p - 0.5)
		"warm":
			return sin(p * TAU) * 0.72 + sin(p * TAU * 2.0) * 0.22 + sin(p * TAU * 3.0) * 0.08
		"saw":
			return 2.0 * p - 1.0
		_:
			return 1.0 if p < 0.5 else -1.0


func _sfx_sweep(f0: float, f1: float, dur: float, amp: float, kind: String) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(f0, f1, t)
		phase += f / SAMPLE_RATE
		var env := minf(t * 14.0, 1.0) * pow(1.0 - t, 1.4)
		buf[i] = _wave(phase, kind) * env * amp
	return _make_wav(buf)


func _sfx_whoosh(dur: float, f0: float, f1: float, amp: float) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(f0, f1, t)
		phase += f / SAMPLE_RATE
		var noise := _rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, noise, 0.25)
		var env := sin(t * PI) * pow(1.0 - t, 0.7)
		buf[i] = (lp * 0.65 + _wave(phase, "tri") * 0.35) * env * amp
	return _make_wav(buf)


func _sfx_impact(dur: float, f0: float, f1: float, amp: float) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(f0, f1, pow(t, 0.5))
		phase += f / SAMPLE_RATE
		var thud := sin(phase * TAU) * exp(-t * 12.0)
		var crack := _rng.randf_range(-1.0, 1.0) * exp(-t * 26.0) * 0.55
		buf[i] = (thud * 0.75 + crack) * amp
	return _make_wav(buf)


func _sfx_spin(dur: float) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := 380.0 + sin(t * TAU * 3.0) * 160.0
		phase += f / SAMPLE_RATE
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.22)
		var env := sin(t * PI) * 0.42
		buf[i] = (_wave(phase, "tri") * 0.45 + lp * 0.55) * env
	return _make_wav(buf)


func _sfx_roar(dur: float) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(118.0, 62.0, pow(t, 0.7)) + sin(t * 95.0) * 14.0
		phase += f / SAMPLE_RATE
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.16)
		var growl := _wave(phase, "saw") * 0.45 + sin(phase * TAU) * 0.35 + lp * 0.45
		var env := minf(t * 12.0, 1.0) * pow(1.0 - t, 0.9) * 0.52
		buf[i] = growl * env
	return _make_wav(buf)


func _sfx_hurt(dur: float) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(260.0, 110.0, t)
		phase += f / SAMPLE_RATE
		var env := pow(1.0 - t, 1.2) * 0.40
		buf[i] = (_wave(phase, "warm") * 0.6 + _wave(phase * 1.5, "saw") * 0.2) * env
	return _make_wav(buf)


func _sfx_notes(midis: Array, step_dur: float, amp: float, kind: String) -> AudioStreamWAV:
	var step_n := int(step_dur * SAMPLE_RATE)
	var tail_n := int(0.14 * SAMPLE_RATE)
	var total := step_n * midis.size() + tail_n
	var buf := PackedFloat32Array()
	buf.resize(total)
	for idx in midis.size():
		var start := idx * step_n
		var f := _midi_to_hz(int(midis[idx]))
		var note_len := step_n + tail_n
		var phase := 0.0
		for j in note_len:
			if start + j >= total:
				break
			var t := float(j) / float(note_len)
			phase += f / SAMPLE_RATE
			var env := minf(t * 25.0, 1.0) * exp(-t * 4.5)
			buf[start + j] += _wave(phase, kind) * env * amp
	return _make_wav(buf)


func _sfx_transform() -> AudioStreamWAV:
	var notes := [67, 72, 76, 79, 84]
	return _sfx_notes(notes, 0.065, 0.36, "warm")


func _sfx_boss_die() -> AudioStreamWAV:
	var dur := 0.95
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(130.0, 32.0, pow(t, 0.5))
		phase += f / SAMPLE_RATE
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.14)
		var boom := (sin(phase * TAU) * 0.65 + lp * 0.55) * exp(-t * 4.2) * 0.55
		buf[i] = boom
	# เติมโน้ตชัยชนะช่วงท้าย
	var fanfare := [72, 76, 79, 84]
	var step_n := int(0.11 * SAMPLE_RATE)
	var offset := int(0.28 * SAMPLE_RATE)
	for idx in fanfare.size():
		var start := offset + idx * step_n
		var f := _midi_to_hz(fanfare[idx])
		var p2 := 0.0
		for j in int(0.28 * SAMPLE_RATE):
			if start + j >= n:
				break
			var t2 := float(j) / (0.28 * SAMPLE_RATE)
			p2 += f / SAMPLE_RATE
			var env := minf(t2 * 20.0, 1.0) * exp(-t2 * 3.8)
			buf[start + j] += _wave(p2, "warm") * env * 0.32
	return _make_wav(buf)


# ---------- สร้างเพลงประกอบ (BGM) แบบวนลูป ----------

func _build_bgm(stage_id: String) -> AudioStreamWAV:
	var bpm := 108.0
	var lead := []
	var bass := []
	var chord := []
	var lead_kind := "warm"
	var drums := false

	match stage_id:
		"village":
			# เพลงหมู่บ้าน: อบอุ่น สดใส กลิ่นอายไทยเพนทาโทนิก (C D E G A) 8 ห้อง (64 จังหวะครึ่ง)
			bpm = 108.0
			lead_kind = "warm"
			drums = false
			lead = [
				72, 74, 76, 79,  76, 0, 74, 72,   74, 76, 79, 81,  79, 0, 0, 0,
				84, 81, 79, 76,  74, 76, 72, 0,   74, 72, 69, 67,  72, 0, 0, 0,
				76, 79, 81, 84,  81, 79, 76, 0,   74, 76, 79, 76,  74, 0, 72, 0,
				69, 72, 74, 76,  79, 76, 74, 72,  74, 76, 74, 72,  72, 0, 0, 0,
			]
			bass = [
				48, 0, 55, 0,  48, 0, 55, 0,   45, 0, 52, 0,  45, 0, 52, 0,
				41, 0, 48, 0,  43, 0, 50, 0,   48, 0, 55, 0,  48, 0, 55, 0,
				48, 0, 55, 0,  45, 0, 52, 0,   41, 0, 48, 0,  43, 0, 50, 0,
				45, 0, 52, 0,  41, 0, 43, 0,   48, 0, 55, 0,  48, 0, 0, 0,
			]
			chord = [60, 64, 67, 72,  60, 64, 67, 72]
		"rice_field":
			# เพลงทุ่งนา: สนุกสนาน ผจญภัย (G major pentatonic)
			bpm = 128.0
			lead_kind = "tri"
			drums = true
			lead = [
				79, 0, 83, 86,   83, 81, 79, 0,   74, 76, 79, 83,  81, 0, 0, 0,
				86, 0, 83, 81,   79, 81, 83, 0,   76, 79, 81, 79,  74, 0, 0, 0,
				79, 81, 83, 86,  88, 86, 83, 0,   81, 83, 86, 83,  81, 79, 76, 0,
				74, 76, 79, 81,  83, 81, 79, 76,  79, 83, 81, 79,  79, 0, 0, 0,
			]
			bass = [
				43, 43, 50, 0,  43, 43, 50, 0,   40, 40, 47, 0,  45, 45, 52, 0,
				38, 38, 45, 0,  40, 40, 47, 0,   43, 43, 50, 0,  38, 38, 45, 0,
				43, 43, 50, 0,  40, 40, 47, 0,   45, 45, 52, 0,  38, 38, 45, 0,
				40, 40, 47, 0,  38, 38, 45, 0,   43, 43, 50, 43, 43, 0, 50, 0,
			]
			chord = [67, 71, 74, 79,  62, 66, 69, 74]
		_:
			# เพลงถ้ำเสือ (บอส): ดุดัน ตื่นเต้น (D minor)
			bpm = 144.0
			lead_kind = "warm"
			drums = true
			lead = [
				74, 0, 74, 77,   79, 0, 77, 76,   74, 0, 72, 74,   69, 0, 0, 0,
				74, 0, 77, 81,   84, 0, 81, 79,   77, 79, 81, 77,  76, 0, 0, 0,
				86, 0, 84, 81,   79, 81, 77, 0,   76, 77, 79, 76,  74, 0, 72, 0,
				69, 72, 74, 76,  77, 79, 81, 77,  79, 77, 76, 72,  74, 0, 0, 0,
			]
			bass = [
				38, 38, 38, 45,  38, 38, 38, 45,  34, 34, 34, 41,  36, 36, 36, 43,
				38, 38, 38, 45,  34, 34, 34, 41,  36, 36, 36, 43,  33, 33, 40, 45,
				38, 38, 38, 45,  34, 34, 34, 41,  36, 36, 36, 43,  38, 38, 45, 38,
				34, 34, 41, 34,  36, 36, 43, 36,  38, 38, 45, 38,  38, 0, 45, 0,
			]
			chord = [62, 65, 69, 74,  57, 60, 64, 69]

	var step_sec := 60.0 / bpm / 2.0  # ความยาว 1 โน้ตเขบ็ต (1/8)
	var step_n := int(roundf(step_sec * SAMPLE_RATE))
	var steps := lead.size()
	var total := step_n * steps
	var buf := PackedFloat32Array()
	buf.resize(total)

	# 1) ทำนองหลัก (Lead)
	for i in steps:
		var midi := int(lead[i])
		if midi <= 0:
			continue
		var hold := 1
		while i + hold < steps and int(lead[i + hold]) == 0 and hold < 3:
			hold += 1
		var note_n := step_n * hold
		var start := i * step_n
		var f := _midi_to_hz(midi)
		var phase := 0.0
		for j in note_n:
			var t := float(j) / float(note_n)
			phase += f / SAMPLE_RATE
			var env := minf(float(j) / (0.015 * SAMPLE_RATE), 1.0) * pow(1.0 - t * 0.7, 1.3)
			buf[start + j] += _wave(phase, lead_kind) * env * 0.24

	# 2) เบส (Bass)
	for i in steps:
		var midi := int(bass[i])
		if midi <= 0:
			continue
		var note_n := int(step_n * 1.4)
		var start := i * step_n
		var f := _midi_to_hz(midi)
		var phase := 0.0
		for j in note_n:
			var idx := (start + j) % total
			var t := float(j) / float(note_n)
			phase += f / SAMPLE_RATE
			var env := minf(float(j) / (0.008 * SAMPLE_RATE), 1.0) * exp(-t * 3.5)
			buf[idx] += (sin(phase * TAU) * 0.75 + _wave(phase, "tri") * 0.25) * env * 0.26

	# 3) คอร์ดคลอเบา ๆ (Arpeggio)
	for i in steps:
		var midi := int(chord[i % chord.size()])
		var start := i * step_n
		var f := _midi_to_hz(midi)
		var phase := 0.0
		for j in step_n:
			var t := float(j) / float(step_n)
			phase += f / SAMPLE_RATE
			var env := minf(float(j) / (0.01 * SAMPLE_RATE), 1.0) * exp(-t * 4.0)
			buf[start + j] += sin(phase * TAU) * env * 0.08

	# 4) กลองจังหวะ (สำหรับฉากต่อสู้)
	if drums:
		for i in steps:
			var start := i * step_n
			var beat := i % 8
			if beat == 0 or beat == 4:
				# Kick
				var kn := mini(int(0.10 * SAMPLE_RATE), step_n)
				var kp := 0.0
				for j in kn:
					var t := float(j) / float(kn)
					kp += lerpf(125.0, 45.0, t) / SAMPLE_RATE
					buf[start + j] += sin(kp * TAU) * exp(-t * 7.0) * 0.28
			elif beat == 2 or beat == 6:
				# Snare
				var sn := mini(int(0.08 * SAMPLE_RATE), step_n)
				for j in sn:
					var t := float(j) / float(sn)
					buf[start + j] += _rng.randf_range(-1.0, 1.0) * exp(-t * 10.0) * 0.14
			else:
				# Hi-hat เบา ๆ
				var hn := mini(int(0.03 * SAMPLE_RATE), step_n)
				var prev := 0.0
				for j in hn:
					var t := float(j) / float(hn)
					var r := _rng.randf_range(-1.0, 1.0)
					var hp := r - prev
					prev = r
					buf[start + j] += hp * exp(-t * 12.0) * 0.06

	return _make_wav(buf, true)
