class_name ClickCard
extends PanelContainer
## Card that behaves like a button: hover highlight, lift, click/Enter emits `pressed`.

signal pressed

var accent := Palette.ACCENT
var enabled := true
var _hover := false
var _base_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _tap := TapDetector.new()


func _init(p_accent: Color = Palette.ACCENT) -> void:
	accent = p_accent
	mouse_filter = Control.MOUSE_FILTER_PASS      # let drags reach the ScrollContainer
	focus_mode = Control.FOCUS_NONE if Layout.touch else Control.FOCUS_ALL   # no focus ring after taps
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_base_style = ThemeBuilder.box(Palette.SURFACE, 18, Palette.BORDER, 1, 22, 18)
	_hover_style = ThemeBuilder.box(Palette.SURFACE_2, 18, accent, 2, 22, 18)
	_hover_style.shadow_color = Color(accent, 0.25)
	_hover_style.shadow_size = 16
	add_theme_stylebox_override("panel", _base_style)
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	focus_entered.connect(_on_enter)
	focus_exited.connect(_on_exit)


func _on_enter() -> void:
	if not enabled or _hover:
		return
	_hover = true
	add_theme_stylebox_override("panel", _hover_style)
	Audio.play("hover", 1.0, -8.0)
	if FX.motion_ok():
		pivot_offset = size / 2.0
		create_tween().tween_property(self, "scale", Vector2.ONE * 1.025, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_exit() -> void:
	if not _hover:
		return
	if has_focus() and get_global_rect().has_point(get_global_mouse_position()):
		return
	_hover = false
	add_theme_stylebox_override("panel", _base_style)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.12)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCROLL_BEGIN:
		_tap.cancel()
		_on_exit()


func set_enabled(value: bool) -> void:
	enabled = value
	modulate.a = 1.0 if value else 0.5
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW


func _gui_input(event: InputEvent) -> void:
	if not enabled:
		return
	if _tap.handle(event) or event.is_action_pressed("ui_accept"):
		accept_event()
		Audio.play("select")
		FX.pop(self, 0.04)
		pressed.emit()


## Round icon badge used on cards.
static func icon_badge(icon_name: String, color: Color, size: int = 52) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", ThemeBuilder.box(Color(color, 0.16), size / 2, Color(color, 0.5), 1, 0, 0))
	p.custom_minimum_size = Vector2(size, size)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(UI.center(UI.icon(icon_name, int(size * 0.5), color)))
	return p
