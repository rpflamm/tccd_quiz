class_name AnswerButton
extends PanelContainer
## Clickable answer card with a key badge (1-6) and wrapping text. Visual states for feedback.

signal pressed(button: AnswerButton)

enum State { NORMAL, SELECTED, CORRECT, WRONG, MISSED, DIMMED }

var original_index := 0
var state := State.NORMAL
var interactive := true
var _hover := false
var _badge: Label
var _badge_panel: PanelContainer
var _text: RichTextLabel
var _mark: TextureRect


func _init(text: String = "", key_number: int = 1, p_original_index: int = 0) -> void:
	original_index = p_original_index
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := UI.hbox(14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_panel = PanelContainer.new()
	_badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_panel.custom_minimum_size = Vector2(34, 34)
	_badge = UI.label(str(key_number), "SubtitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge_panel.add_child(_badge)
	_badge_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_badge_panel)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", 19)
	_text.add_theme_font_size_override("mono_font_size", 17)
	_text.text = TextFormat.inline_code(text)
	row.add_child(_text)

	_mark = UI.icon("check", 26, Palette.SUCCESS)
	_mark.visible = false
	_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_mark)
	add_child(row)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_refresh)
	focus_exited.connect(_refresh)
	_refresh()


func _on_mouse_entered() -> void:
	_hover = true
	_refresh()
	if interactive:
		Audio.play("hover", 1.0, -10.0)


func _on_mouse_exited() -> void:
	_hover = false
	_refresh()


func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit(self)
	elif event.is_action_pressed("ui_accept"):
		accept_event()
		pressed.emit(self)


func set_state(s: State) -> void:
	state = s
	_refresh()


func set_interactive(value: bool) -> void:
	interactive = value
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW
	_refresh()


func _refresh() -> void:
	var bg := Palette.SURFACE
	var border := Palette.BORDER
	var border_w := 1
	var badge_bg := Palette.SURFACE_3
	var badge_fg := Palette.MUTED
	var text_alpha := 1.0
	_mark.visible = false
	match state:
		State.NORMAL:
			if interactive and (_hover or has_focus()):
				bg = Palette.SURFACE_2
				border = Palette.ACCENT
				badge_bg = Color(Palette.ACCENT, 0.25)
				badge_fg = Palette.ACCENT_2
		State.SELECTED:
			bg = Color(Palette.ACCENT, 0.14)
			border = Palette.ACCENT
			border_w = 2
			badge_bg = Palette.ACCENT
			badge_fg = Color("1a1206")
		State.CORRECT:
			bg = Color(Palette.SUCCESS, 0.16)
			border = Palette.SUCCESS
			border_w = 2
			badge_bg = Palette.SUCCESS
			badge_fg = Color("06210f")
			_mark.visible = true
			_mark.texture = UI.icon_texture("check")
			_mark.modulate = Palette.SUCCESS
		State.WRONG:
			bg = Color(Palette.ERROR, 0.16)
			border = Palette.ERROR
			border_w = 2
			badge_bg = Palette.ERROR
			badge_fg = Color("2a0509")
			_mark.visible = true
			_mark.texture = UI.icon_texture("cross")
			_mark.modulate = Palette.ERROR
		State.MISSED:
			bg = Palette.SURFACE
			border = Palette.SUCCESS
			border_w = 2
			badge_bg = Color(Palette.SUCCESS, 0.3)
			badge_fg = Palette.SUCCESS
			_mark.visible = true
			_mark.texture = UI.icon_texture("check")
			_mark.modulate = Color(Palette.SUCCESS, 0.6)
		State.DIMMED:
			text_alpha = 0.45
	if has_focus() and interactive and state != State.NORMAL:
		border = Palette.ACCENT_2
	add_theme_stylebox_override("panel", ThemeBuilder.box(bg, 14, border, border_w, 16, 12))
	_badge_panel.add_theme_stylebox_override("panel", ThemeBuilder.box(badge_bg, 9, Color.TRANSPARENT, 0, 4, 2))
	_badge.add_theme_color_override("font_color", badge_fg)
	_text.modulate.a = text_alpha
