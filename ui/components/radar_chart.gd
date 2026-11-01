class_name RadarChart
extends Control
## Spider/radar chart for per-domain values (0..1). Animated on show.

var labels: PackedStringArray = []
var values: PackedFloat32Array = []
var colors: Array[Color] = []
var secondary: PackedFloat32Array = []   # optional second series (e.g. accuracy)
var _anim := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(420, 380)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_data(p_labels: PackedStringArray, p_values: PackedFloat32Array, p_colors: Array[Color], p_secondary: PackedFloat32Array = PackedFloat32Array()) -> void:
	labels = p_labels
	values = p_values
	colors = p_colors
	secondary = p_secondary
	_anim = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float): _anim = v; queue_redraw(), 0.0, 1.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _point(i: int, n: int, radius: float, center: Vector2) -> Vector2:
	var angle := -PI / 2.0 + TAU * i / n
	return center + Vector2(cos(angle), sin(angle)) * radius


func _draw() -> void:
	var n := labels.size()
	if n < 3:
		return
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 70.0
	# grid
	for ring in [0.25, 0.5, 0.75, 1.0]:
		var pts := PackedVector2Array()
		for i in n + 1:
			pts.append(_point(i % n, n, radius * ring, center))
		draw_polyline(pts, Color(Palette.BORDER, 0.8 if ring == 1.0 else 0.45), 1.5, true)
	for i in n:
		draw_line(center, _point(i, n, radius, center), Color(Palette.BORDER, 0.45), 1.0, true)
	# secondary series (outline only)
	if secondary.size() == n:
		var sp := PackedVector2Array()
		for i in n + 1:
			sp.append(_point(i % n, n, radius * clampf(secondary[i % n], 0.02, 1.0) * _anim, center))
		draw_polyline(sp, Color(Palette.INFO, 0.9), 2.0, true)
	# main series
	var poly := PackedVector2Array()
	for i in n:
		poly.append(_point(i, n, radius * clampf(values[i], 0.02, 1.0) * _anim, center))
	draw_colored_polygon(poly, Color(Palette.ACCENT, 0.22))
	var outline := poly.duplicate()
	outline.append(poly[0])
	draw_polyline(outline, Palette.ACCENT, 2.5, true)
	var font := ThemeBuilder.font(ThemeBuilder.FONT_SEMIBOLD)
	for i in n:
		var c: Color = colors[i] if i < colors.size() else Palette.ACCENT
		draw_circle(poly[i], 5.0, c)
		var lp := _point(i, n, radius + 34.0, center)
		var text := labels[i]
		var fs := 13
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, lp - Vector2(tw / 2.0, -4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.MUTED)
		var pct := "%d%%" % int(round(values[i] * 100))
		var pw := font.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, lp - Vector2(pw / 2.0, -20), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, c)
