class_name TimerBar
extends Control
## Rounded countdown bar: colour shifts from green to orange to red; pulses when low.

var fraction := 1.0:
	set(v):
		fraction = clampf(v, 0.0, 1.0)
		queue_redraw()
var low_threshold := 0.25


func _init() -> void:
	custom_minimum_size = Vector2(120, 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if fraction < low_threshold:
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var radius := size.y / 2.0
	_rounded(r, Palette.SURFACE_3, radius)
	if fraction <= 0.0:
		return
	var color: Color
	if fraction > 0.5:
		color = Palette.SUCCESS.lerp(Palette.WARNING, (1.0 - fraction) * 2.0)
	else:
		color = Palette.WARNING.lerp(Palette.ERROR, clampf((0.5 - fraction) * 2.5, 0.0, 1.0))
	if fraction < low_threshold:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0)
		color = color.lerp(Color.WHITE, pulse * 0.35)
	var w := maxf(size.x * fraction, size.y)
	_rounded(Rect2(Vector2.ZERO, Vector2(w, size.y)), color, radius)


func _rounded(r: Rect2, c: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(int(radius))
	draw_style_box(sb, r)
