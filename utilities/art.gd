class_name Art
## เครื่องมือวาดภาพแบบขอบเนียน (anti-alias) ใช้ร่วมกันทั้งเกม
## ci = ตัวที่กำลังวาด (ส่ง self เข้ามา)

const INK := Color(0.34, 0.22, 0.18)  # สีเส้นขอบ (น้ำตาลเข้ม นุ่มกว่าสีดำ)

static var _boxes := {}


static func circle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r, col, true, -1.0, true)


static func ellipse_points(c: Vector2, rx: float, ry: float, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## รูปหลายเหลี่ยมขอบเนียน
static func poly(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	ci.draw_colored_polygon(pts, col)
	if col.a > 0.98:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, col, 1.5, true)


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	poly(ci, ellipse_points(c, rx, ry), col)


## วงรีมีเส้นขอบ
static func blob(ci: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, w := 3.0, ink := INK) -> void:
	ellipse(ci, c, rx + w, ry + w, ink)
	ellipse(ci, c, rx, ry, fill)


## สี่เหลี่ยมมุมมน
static func rrect(ci: CanvasItem, r: Rect2, col: Color, radius := 8.0) -> void:
	var key := "%s|%d" % [col.to_html(), int(radius)]
	var sb: StyleBoxFlat = _boxes.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(int(radius))
		sb.corner_detail = 6
		sb.anti_aliasing = true
		_boxes[key] = sb
	ci.draw_style_box(sb, r)


## สี่เหลี่ยมมุมมนมีเส้นขอบ
static func box(ci: CanvasItem, r: Rect2, fill: Color, radius := 8.0, w := 3.0, ink := INK) -> void:
	rrect(ci, r.grow(w), ink, radius + w)
	rrect(ci, r, fill, radius)


## สี่เหลี่ยมไล่สีบนลงล่าง
static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(
		PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


## เส้นปลายมน
static func line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(a, b, col, w, true)
	circle(ci, a, w * 0.5, col)
	circle(ci, b, w * 0.5, col)


## เส้นโค้งปลายมน
static func curve(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	ci.draw_polyline(pts, col, w, true)
	circle(ci, pts[0], w * 0.5, col)
	circle(ci, pts[pts.size() - 1], w * 0.5, col)


static func bezier(a: Vector2, ctrl: Vector2, b: Vector2, n := 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return pts


## เงาใต้เท้า
static func shadow(ci: CanvasItem, c: Vector2, rx: float) -> void:
	ellipse(ci, c, rx, rx * 0.24, Color(0.1, 0.05, 0.15, 0.18))


## แสงเรือง
static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	for i in 12:
		circle(ci, c, r * (1.0 - i * 0.08), Color(col.r, col.g, col.b, col.a * 0.09))


## ใบไม้โค้ง (ใช้กับต้นกล้วย ต้นมะพร้าว)
static func leaf(ci: CanvasItem, base: Vector2, ctrl: Vector2, tip: Vector2, width: float, col: Color, rib: Color) -> void:
	var mid := bezier(base, ctrl, tip, 10)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in mid.size():
		var t := float(i) / (mid.size() - 1)
		var dir := (mid[mini(i + 1, mid.size() - 1)] - mid[maxi(i - 1, 0)]).normalized()
		var half := width * pow(sin(PI * clampf(t * 0.92 + 0.04, 0.0, 1.0)), 0.7)
		left.append(mid[i] + dir.orthogonal() * half)
		right.append(mid[i] - dir.orthogonal() * half)
	right.reverse()
	left.append_array(right)
	poly(ci, left, col)
	ci.draw_polyline(mid, rib, 2.0, true)
