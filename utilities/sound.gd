extends Node
## ระบบเสียงของเกม (autoload ชื่อ Sound): สังเคราะห์ดนตรี (BGM) และเอฟเฟกต์ (SFX) แบบ FM + Stereo Delay
## ปรับจูนให้กระแทกกระทั้น มีมิติ และรองรับการ export ลงเว็บ (Web Audio)

const SFX_RATE := 44100
const BGM_RATE := 32000
const SFX_POOL_SIZE := 12

var muted := false
var bgm_volume_db := -9.0
var sfx_volume_db := -4.0

var _bgm_player: AudioStreamPlayer
var _bgm_tween: Tween
var _current_bgm := ""
var _bgm_cache := {}
var _sfx_cache := {}
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


func play(sfx_name: String, pitch_jitter := 0.0, vol_offset_db := 0.0) -> void:
	if muted or not _sfx_cache.has(sfx_name):
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	p.stream = _sfx_cache[sfx_name]
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 1.0
	p.volume_db = sfx_volume_db + vol_offset_db
	p.play()


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
		_bgm_tween.tween_property(_bgm_player, "volume_db", -40.0, 0.22)
		_bgm_tween.tween_callback(func() -> void:
			_bgm_player.stream = next_stream
			_bgm_player.play()
		)
		_bgm_tween.tween_property(_bgm_player, "volume_db", bgm_volume_db, 0.30)
	else:
		_bgm_player.stream = next_stream
		_bgm_player.volume_db = -28.0
		_bgm_player.play()
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", bgm_volume_db, 0.35)


func _fade_out_bgm() -> void:
	if _bgm_tween:
		_bgm_tween.kill()
	if _bgm_player.playing:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", -40.0, 0.25)
		_bgm_tween.tween_callback(_bgm_player.stop)


# ---------- ตัวช่วยสร้างคลื่นเสียงและใส่ Stereo Echo ----------

func _make_wav_stereo(left: PackedFloat32Array, right: PackedFloat32Array, rate: int, loop := false) -> AudioStreamWAV:
	var n := left.size()
	var data := PackedByteArray()
	data.resize(n * 4)
	for i in n:
		# soft clip แบบ tanh เพื่อไม่ให้เสียงแตกแต่ได้ความแน่น
		var l := left[i]
		var r := right[i]
		l = l / (1.0 + absf(l) * 0.35)
		r = r / (1.0 + absf(r) * 0.35)
		data.encode_s16(i * 4, int(clampf(l, -0.98, 0.98) * 32767.0))
		data.encode_s16(i * 4 + 2, int(clampf(r, -0.98, 0.98) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = n
	return wav


## ใส่เสียงสะท้อนสเตอริโอ (Ping-Pong Delay) ให้เสียงกว้างและไม่แห้ง
func _add_stereo_echo(mono: PackedFloat32Array, rate: int, ms_l: float, ms_r: float, wet: float, pad_tail := true) -> Array:
	var d_l := int(ms_l * 0.001 * rate)
	var d_r := int(ms_r * 0.001 * rate)
	var extra := maxi(d_l, d_r) * 2 if pad_tail else 0
	var n := mono.size() + extra
	var l := PackedFloat32Array()
	var r := PackedFloat32Array()
	l.resize(n)
	r.resize(n)
	for i in mono.size():
		l[i] = mono[i]
		r[i] = mono[i]
	for i in n:
		if i >= d_l:
			l[i] += r[i - d_l] * wet
		if i >= d_r:
			r[i] += l[i - d_r] * wet * 0.85
	return [l, r]


func _midi_to_hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


# ---------- เอฟเฟกต์ (SFX) แบบหลายชั้น 44.1kHz ----------

func _build_all_sfx() -> void:
	_sfx_cache["jump"] = _sfx_jump()
	_sfx_cache["land"] = _sfx_land()
	_sfx_cache["slash"] = _sfx_slash(false)
	_sfx_cache["claw"] = _sfx_slash(true)
	_sfx_cache["hit"] = _sfx_hit(false)
	_sfx_cache["heavy_hit"] = _sfx_hit(true)
	_sfx_cache["dash"] = _sfx_dash()
	_sfx_cache["spin"] = _sfx_spin()
	_sfx_cache["roar"] = _sfx_roar()
	_sfx_cache["hurt"] = _sfx_hurt()
	_sfx_cache["enemy_die"] = _sfx_enemy_die()
	_sfx_cache["boss_die"] = _sfx_boss_die()
	_sfx_cache["coin"] = _sfx_chime([95, 100], 0.065, 0.50, 1.8)
	_sfx_cache["item"] = _sfx_chime([84, 91, 96], 0.06, 0.45, 2.2)
	_sfx_cache["potion"] = _sfx_chime([72, 76, 79, 84, 88], 0.055, 0.48, 1.4)
	_sfx_cache["level_up"] = _sfx_level_up()
	_sfx_cache["transform"] = _sfx_transform()
	_sfx_cache["portal"] = _sfx_portal()
	_sfx_cache["talk"] = _sfx_blip(680.0, 0.038, 0.25)
	_sfx_cache["ui"] = _sfx_blip(520.0, 0.045, 0.28)
	_sfx_cache["quest"] = _sfx_chime([79, 83, 86, 91], 0.075, 0.48, 2.0)


func _sfx_jump() -> AudioStreamWAV:
	# กระโดดสไตล์อาเขต: พุ่งขึ้นเร็ว + ฮาร์มอนิกใส
	var dur := 0.14
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(260.0, 740.0, pow(t, 0.65))
		p += f / SFX_RATE
		var env := minf(t * 24.0, 1.0) * pow(1.0 - t, 1.2)
		var wave := sin(p * TAU) * 0.65 + sin(p * TAU * 2.0) * 0.25
		buf[i] = wave * env * 0.55
	var st := _add_stereo_echo(buf, SFX_RATE, 24.0, 36.0, 0.18)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_land() -> AudioStreamWAV:
	var dur := 0.09
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		p += lerpf(135.0, 48.0, t) / SFX_RATE
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.15)
		var env := exp(-t * 14.0)
		buf[i] = (sin(p * TAU) * 0.7 + lp * 0.4) * env * 0.45
	return _make_wav_stereo(buf, buf, SFX_RATE)


func _sfx_slash(is_claw: bool) -> AudioStreamWAV:
	# เสียงฟัน/ตะปบ: เสียงลมแหวกอากาศ + ประกายคมดาบ FM
	var dur := 0.17 if is_claw else 0.15
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p := 0.0
	var mod_p := 0.0
	var lp1 := 0.0
	var lp2 := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(1600.0 if is_claw else 1100.0, 240.0, pow(t, 0.55))
		p += f / SFX_RATE
		mod_p += (f * 2.7) / SFX_RATE
		var noise := _rng.randf_range(-1.0, 1.0)
		# bandpass คร่าว ๆ เพื่อเสียงลมฟันคม ๆ
		lp1 = lerpf(lp1, noise, 0.45)
		lp2 = lerpf(lp2, lp1, 0.18)
		var bp := lp1 - lp2
		var env := minf(t * 28.0, 1.0) * pow(1.0 - t, 1.4)
		var metal := sin(p * TAU + sin(mod_p * TAU) * (2.2 if is_claw else 1.4)) * exp(-t * 14.0)
		buf[i] = (bp * 1.4 + metal * 0.45) * env * 0.65
	var st := _add_stereo_echo(buf, SFX_RATE, 22.0, 34.0, 0.2)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_hit(heavy: bool) -> AudioStreamWAV:
	# เสียงตีโดน: ซับเบสกระแทกหนัก + เสียงฟาดแหลม + อิ่มตัว
	var dur := 0.22 if heavy else 0.14
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p_sub := 0.0
	var p_mid := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		p_sub += lerpf(185.0 if heavy else 220.0, 38.0, pow(t, 0.4)) / SFX_RATE
		p_mid += lerpf(720.0, 130.0, pow(t, 0.35)) / SFX_RATE
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.55)
		var sub := sin(p_sub * TAU) * exp(-t * (8.0 if heavy else 12.0))
		var smack := (sin(p_mid * TAU) * 0.5 + lp * 0.85) * exp(-t * 28.0)
		var s := (sub * 0.85 + smack * 0.75) * (1.15 if heavy else 0.9)
		buf[i] = tanh(s * 1.4) * 0.75
	var st := _add_stereo_echo(buf, SFX_RATE, 28.0, 42.0, 0.22 if heavy else 0.14)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_dash() -> AudioStreamWAV:
	# พุ่งตัว: ลมพุ่งแรง + ป๊อปต้นจังหวะ
	var dur := 0.24
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p := 0.0
	var lp1 := 0.0
	var lp2 := 0.0
	for i in n:
		var t := float(i) / float(n)
		p += lerpf(320.0, 980.0, pow(t, 0.7)) / SFX_RATE
		var noise := _rng.randf_range(-1.0, 1.0)
		lp1 = lerpf(lp1, noise, 0.35)
		lp2 = lerpf(lp2, lp1, 0.12)
		var whoosh := (lp1 - lp2) * 1.6
		var env := minf(t * 20.0, 1.0) * pow(1.0 - t, 1.2)
		buf[i] = (whoosh + sin(p * TAU) * 0.25) * env * 0.6
	var st := _add_stereo_echo(buf, SFX_RATE, 32.0, 48.0, 0.25)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_spin() -> AudioStreamWAV:
	var dur := 0.36
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p := 0.0
	var lp1 := 0.0
	var lp2 := 0.0
	for i in n:
		var t := float(i) / float(n)
		var lfo := 0.5 + 0.5 * sin(t * TAU * 4.5)
		p += (360.0 + lfo * 380.0) / SFX_RATE
		lp1 = lerpf(lp1, _rng.randf_range(-1.0, 1.0), 0.38)
		lp2 = lerpf(lp2, lp1, 0.14)
		var env := sin(t * PI) * (0.55 + 0.45 * lfo)
		buf[i] = ((lp1 - lp2) * 1.4 + sin(p * TAU) * 0.35) * env * 0.55
	var st := _add_stereo_echo(buf, SFX_RATE, 35.0, 52.0, 0.25)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_roar() -> AudioStreamWAV:
	# เสือคำราม: คลื่นความถี่ต่ำ + FM สั่นดุดัน + ลมคำราม + ก้องในถ้ำ
	var dur := 0.62
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p1 := 0.0
	var p2 := 0.0
	var mod := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(135.0, 58.0, pow(t, 0.65)) + sin(t * 70.0) * 10.0
		p1 += f / SFX_RATE
		p2 += (f * 0.5) / SFX_RATE
		mod += (f * 1.5) / SFX_RATE
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.18)
		var fm := sin(p1 * TAU + sin(mod * TAU) * 2.4)
		var sub := sin(p2 * TAU)
		var env := minf(t * 16.0, 1.0) * pow(1.0 - t, 0.9)
		buf[i] = tanh((fm * 0.6 + sub * 0.45 + lp * 0.55) * 1.5) * env * 0.65
	var st := _add_stereo_echo(buf, SFX_RATE, 55.0, 82.0, 0.32)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_hurt() -> AudioStreamWAV:
	var dur := 0.20
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p := 0.0
	var mod := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(310.0, 115.0, pow(t, 0.7))
		p += f / SFX_RATE
		mod += (f * 1.4) / SFX_RATE
		var env := minf(t * 30.0, 1.0) * pow(1.0 - t, 1.3)
		buf[i] = sin(p * TAU + sin(mod * TAU) * 1.8) * env * 0.55
	var st := _add_stereo_echo(buf, SFX_RATE, 25.0, 38.0, 0.2)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_enemy_die() -> AudioStreamWAV:
	# ป๊อปแตก + โน้ตเด้งน่ารัก
	var dur := 0.24
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(520.0, 160.0, t) if t < 0.35 else lerpf(420.0, 880.0, (t - 0.35) / 0.65)
		p += f / SFX_RATE
		var env := minf(t * 30.0, 1.0) * pow(1.0 - t, 1.2)
		buf[i] = (sin(p * TAU) * 0.7 + sin(p * TAU * 2.0) * 0.25) * env * 0.5
	var st := _add_stereo_echo(buf, SFX_RATE, 32.0, 48.0, 0.24)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_chime(midis: Array, step_dur: float, amp: float, fm_idx: float) -> AudioStreamWAV:
	var step_n := int(step_dur * SFX_RATE)
	var tail_n := int(0.24 * SFX_RATE)
	var total := step_n * midis.size() + tail_n
	var buf := PackedFloat32Array()
	buf.resize(total)
	for idx in midis.size():
		var start := idx * step_n
		var f := _midi_to_hz(int(midis[idx]))
		var note_len := step_n + tail_n
		var p := 0.0
		var mp := 0.0
		for j in note_len:
			if start + j >= total:
				break
			var t := float(j) / float(note_len)
			p += f / SFX_RATE
			mp += (f * 2.0) / SFX_RATE
			var mod_env := exp(-t * 10.0) * fm_idx
			var env := minf(t * 40.0, 1.0) * exp(-t * 5.2)
			buf[start + j] += sin(p * TAU + sin(mp * TAU) * mod_env) * env * amp
	var st := _add_stereo_echo(buf, SFX_RATE, 45.0, 68.0, 0.28)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_level_up() -> AudioStreamWAV:
	# แฟนแฟร์เลเวลอัป: ไล่โน้ต + คอร์ดประกาย
	var notes := [72, 76, 79, 84, 88, 91]
	var step_n := int(0.065 * SFX_RATE)
	var tail_n := int(0.45 * SFX_RATE)
	var total := step_n * notes.size() + tail_n
	var buf := PackedFloat32Array()
	buf.resize(total)
	for idx in notes.size():
		var start := idx * step_n
		var f := _midi_to_hz(notes[idx])
		var dur_n := tail_n if idx >= notes.size() - 2 else step_n + int(0.18 * SFX_RATE)
		var p := 0.0
		var mp := 0.0
		for j in dur_n:
			if start + j >= total:
				break
			var t := float(j) / float(dur_n)
			p += f / SFX_RATE
			mp += (f * 2.0) / SFX_RATE
			var env := minf(t * 35.0, 1.0) * exp(-t * 3.8)
			buf[start + j] += sin(p * TAU + sin(mp * TAU) * exp(-t * 8.0) * 1.8) * env * 0.38
	var st := _add_stereo_echo(buf, SFX_RATE, 55.0, 82.0, 0.32)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_transform() -> AudioStreamWAV:
	var dur := 0.48
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p1 := 0.0
	var p2 := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(330.0, 990.0, pow(t, 0.6))
		p1 += f / SFX_RATE
		p2 += (f * 1.5) / SFX_RATE
		var env := sin(t * PI) * 0.45
		buf[i] = (sin(p1 * TAU) * 0.6 + sin(p2 * TAU) * 0.4) * env
	var st := _add_stereo_echo(buf, SFX_RATE, 48.0, 72.0, 0.34)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_portal() -> AudioStreamWAV:
	return _sfx_chime([67, 74, 79, 86, 91], 0.055, 0.42, 1.6)


func _sfx_boss_die() -> AudioStreamWAV:
	var dur := 1.05
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		p += lerpf(150.0, 32.0, pow(t, 0.45)) / SFX_RATE
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.16)
		buf[i] = tanh((sin(p * TAU) * 0.8 + lp * 0.7) * 1.5) * exp(-t * 3.8) * 0.65
	var fanfare := [72, 76, 79, 84]
	var step_n := int(0.11 * SFX_RATE)
	var offset := int(0.30 * SFX_RATE)
	for idx in fanfare.size():
		var start := offset + idx * step_n
		var f := _midi_to_hz(fanfare[idx])
		var p2 := 0.0
		var mp2 := 0.0
		var fn := int(0.38 * SFX_RATE)
		for j in fn:
			if start + j >= n:
				break
			var t2 := float(j) / float(fn)
			p2 += f / SFX_RATE
			mp2 += (f * 2.0) / SFX_RATE
			var env := minf(t2 * 25.0, 1.0) * exp(-t2 * 3.5)
			buf[start + j] += sin(p2 * TAU + sin(mp2 * TAU) * 1.5 * exp(-t2 * 6.0)) * env * 0.40
	var st := _add_stereo_echo(buf, SFX_RATE, 60.0, 90.0, 0.30)
	return _make_wav_stereo(st[0], st[1], SFX_RATE)


func _sfx_blip(freq: float, dur: float, amp: float) -> AudioStreamWAV:
	var n := int(dur * SFX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var p := 0.0
	for i in n:
		var t := float(i) / float(n)
		p += lerpf(freq, freq * 1.15, t) / SFX_RATE
		var env := minf(t * 30.0, 1.0) * pow(1.0 - t, 1.5)
		buf[i] = sin(p * TAU) * env * amp
	return _make_wav_stereo(buf, buf, SFX_RATE)


# ---------- เพลงประกอบ (BGM) 32kHz Stereo ----------

func _build_bgm(stage_id: String) -> AudioStreamWAV:
	var bpm := 116.0
	var lead := []
	var bass := []
	var arp := []
	var groove := "light"

	match stage_id:
		"village":
			# หมู่บ้าน: สดใส น่ารัก คล้ายเพลงเมือง MapleStory (C major)
			bpm = 114.0
			groove = "light"
			lead = [
				76, 0, 79, 84,   83, 0, 79, 0,   77, 76, 74, 72,  74, 0, 0, 0,
				74, 0, 77, 81,   79, 0, 76, 0,   74, 72, 71, 69,  67, 0, 0, 0,
				76, 0, 79, 84,   83, 84, 86, 0,  84, 81, 79, 76,  74, 0, 0, 0,
				72, 74, 76, 79,  81, 79, 77, 74, 76, 74, 72, 71,  72, 0, 0, 0,
			]
			bass = [
				48, 0, 55, 0,  48, 0, 55, 0,   41, 0, 48, 0,  43, 0, 50, 0,
				45, 0, 52, 0,  40, 0, 47, 0,   41, 0, 48, 0,  43, 0, 50, 0,
				48, 0, 55, 0,  43, 0, 50, 0,   45, 0, 52, 0,  41, 0, 48, 0,
				41, 0, 43, 0,  45, 0, 41, 0,   43, 0, 50, 0,  48, 0, 55, 0,
			]
			arp = [60, 64, 67, 72,  65, 69, 72, 77,  67, 71, 74, 79,  60, 64, 67, 72]
		"rice_field":
			# ทุ่งนา: จังหวะมันส์ สนุก ผจญภัย (G major / Mixolydian)
			bpm = 136.0
			groove = "adventure"
			lead = [
				79, 0, 83, 86,   83, 81, 79, 83,  86, 0, 88, 86,   83, 0, 0, 0,
				81, 0, 83, 86,   88, 0, 86, 83,   81, 79, 76, 79,  74, 0, 0, 0,
				79, 81, 83, 86,  91, 0, 88, 86,   83, 81, 79, 76,  81, 0, 0, 0,
				74, 76, 79, 81,  83, 86, 88, 86,  83, 81, 79, 76,  79, 0, 0, 0,
			]
			bass = [
				43, 43, 55, 43,  43, 43, 55, 43,  40, 40, 52, 40,  45, 45, 57, 45,
				38, 38, 50, 38,  40, 40, 52, 40,  43, 43, 55, 43,  38, 38, 50, 38,
				43, 43, 55, 43,  40, 40, 52, 40,  45, 45, 57, 45,  38, 38, 50, 38,
				40, 40, 52, 40,  38, 38, 50, 38,  43, 43, 55, 43,  43, 50, 55, 0,
			]
			arp = [67, 71, 74, 79,  64, 67, 71, 76,  62, 66, 69, 74,  67, 71, 74, 79]
		_:
			# ถ้ำเสือ (บอส): ดุดัน เร่งเร้า แบบเพลงบอส (D minor)
			bpm = 152.0
			groove = "boss"
			lead = [
				74, 0, 74, 77,   81, 0, 79, 77,   76, 0, 74, 72,   74, 0, 69, 0,
				74, 0, 77, 81,   86, 0, 84, 81,   79, 81, 84, 79,  81, 0, 0, 0,
				86, 0, 86, 84,   81, 79, 77, 0,   76, 77, 79, 81,  74, 0, 72, 0,
				69, 72, 74, 77,  79, 81, 84, 81,  79, 77, 76, 72,  74, 0, 0, 0,
			]
			bass = [
				38, 38, 50, 38,  38, 38, 50, 38,  34, 34, 46, 34,  36, 36, 48, 36,
				38, 38, 50, 38,  34, 34, 46, 34,  36, 36, 48, 36,  33, 33, 45, 33,
				38, 38, 50, 38,  34, 34, 46, 34,  36, 36, 48, 36,  38, 38, 50, 38,
				34, 34, 46, 34,  36, 36, 48, 36,  38, 38, 50, 38,  38, 45, 50, 0,
			]
			arp = [62, 65, 69, 74,  58, 62, 65, 70,  60, 64, 67, 72,  57, 60, 64, 69]

	var step_sec := 60.0 / bpm / 2.0
	var step_n := int(roundf(step_sec * BGM_RATE))
	var steps := lead.size()
	var total := step_n * steps
	var buf := PackedFloat32Array()
	buf.resize(total)

	# 1) Lead แบบ Detuned FM (หนาและไพเราะ)
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
		var p1 := 0.0
		var p2 := 0.0
		var mp := 0.0
		var fm_amt := 1.4 if groove == "boss" else 0.9
		for j in note_n:
			var t := float(j) / float(note_n)
			p1 += f / BGM_RATE
			p2 += (f * 1.004) / BGM_RATE
			mp += (f * 2.0) / BGM_RATE
			var env := minf(float(j) / (0.012 * BGM_RATE), 1.0) * pow(1.0 - t * 0.65, 1.2)
			var mod := sin(mp * TAU) * fm_amt * exp(-t * 4.0)
			buf[start + j] += (sin(p1 * TAU + mod) + sin(p2 * TAU)) * 0.5 * env * 0.24

	# 2) FM Slap Bass
	for i in steps:
		var midi := int(bass[i])
		if midi <= 0:
			continue
		var note_n := int(step_n * 1.25)
		var start := i * step_n
		var f := _midi_to_hz(midi)
		var p := 0.0
		var mp := 0.0
		for j in note_n:
			var idx := (start + j) % total
			var t := float(j) / float(note_n)
			p += f / BGM_RATE
			mp += (f * 2.0) / BGM_RATE
			var env := minf(float(j) / (0.006 * BGM_RATE), 1.0) * exp(-t * 3.8)
			buf[idx] += sin(p * TAU + sin(mp * TAU) * 1.6 * exp(-t * 8.0)) * env * 0.26

	# 3) คอร์ด Arpeggio
	for i in steps:
		var midi := int(arp[i % arp.size()])
		var start := i * step_n
		var f := _midi_to_hz(midi)
		var p := 0.0
		for j in step_n:
			var t := float(j) / float(step_n)
			p += f / BGM_RATE
			var env := minf(float(j) / (0.008 * BGM_RATE), 1.0) * exp(-t * 4.5)
			buf[start + j] += sin(p * TAU) * env * 0.10

	# 4) กลองจังหวะ
	for i in steps:
		var start := i * step_n
		var beat := i % 8
		if groove == "light":
			if beat == 0 or beat == 4:
				var kn := mini(int(0.08 * BGM_RATE), step_n)
				var kp := 0.0
				for j in kn:
					var t := float(j) / float(kn)
					kp += lerpf(110.0, 48.0, t) / BGM_RATE
					buf[start + j] += sin(kp * TAU) * exp(-t * 8.0) * 0.18
			elif beat % 2 == 1:
				var hn := mini(int(0.025 * BGM_RATE), step_n)
				var prev := 0.0
				for j in hn:
					var t := float(j) / float(hn)
					var r := _rng.randf_range(-1.0, 1.0)
					buf[start + j] += (r - prev) * exp(-t * 14.0) * 0.05
		else:
			if beat == 0 or beat == 4 or (groove == "boss" and beat == 3):
				var kn := mini(int(0.10 * BGM_RATE), step_n)
				var kp := 0.0
				for j in kn:
					var t := float(j) / float(kn)
					kp += lerpf(145.0, 44.0, pow(t, 0.6)) / BGM_RATE
					buf[start + j] += sin(kp * TAU) * exp(-t * 6.5) * 0.30
			if beat == 2 or beat == 6:
				var sn := mini(int(0.09 * BGM_RATE), step_n)
				var sp := 0.0
				for j in sn:
					var t := float(j) / float(sn)
					sp += lerpf(220.0, 140.0, t) / BGM_RATE
					buf[start + j] += (sin(sp * TAU) * 0.4 + _rng.randf_range(-1.0, 1.0) * 0.7) * exp(-t * 10.0) * 0.18
			else:
				var hn := mini(int(0.03 * BGM_RATE), step_n)
				var prev := 0.0
				for j in hn:
					var t := float(j) / float(hn)
					var r := _rng.randf_range(-1.0, 1.0)
					buf[start + j] += (r - prev) * exp(-t * 12.0) * 0.06

	var st := _add_stereo_echo(buf, BGM_RATE, 70.0, 105.0, 0.20, false)
	return _make_wav_stereo(st[0], st[1], BGM_RATE, true)
