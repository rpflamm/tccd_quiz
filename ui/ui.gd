class_name UI
extends RefCounted
## Small node factory to build screens in code with consistent styling.

static var _icons := {}


static func icon_texture(name: String) -> Texture2D:
	if not _icons.has(name):
		var path := "res://assets/icons/%s.svg" % name
		_icons[name] = load(path) if ResourceLoader.exists(path) else null
	return _icons[name]


static func icon(name: String, size: int = 24, color: Color = Palette.TEXT) -> TextureRect:
	var r := TextureRect.new()
	r.texture = icon_texture(name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.modulate = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func label(text: String, variation: String = "", align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	if not variation.is_empty():
		l.theme_type_variation = variation
	l.horizontal_alignment = align
	return l


static func wrap_label(text: String, variation: String = "", align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text, variation, align)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func button(text: String, icon_name: String = "", variation: String = "", callback: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	if not icon_name.is_empty():
		b.icon = icon_texture(icon_name)
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 22)
	if not variation.is_empty():
		b.theme_type_variation = variation
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if callback.is_valid():
		b.pressed.connect(callback)
	b.pressed.connect(func(): Audio.play("click"))
	b.mouse_entered.connect(func(): Audio.play("hover", 1.0, -8.0))
	return b


static func vbox(separation: int = 12, children: Array = []) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", separation)
	for c in children:
		b.add_child(c)
	return b


static func hbox(separation: int = 12, children: Array = []) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", separation)
	for c in children:
		b.add_child(c)
	return b


static func margin(child: Control, l: int, t: int = -1, r: int = -1, b: int = -1) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", l if t < 0 else t)
	m.add_theme_constant_override("margin_right", l if r < 0 else r)
	m.add_theme_constant_override("margin_bottom", (l if t < 0 else t) if b < 0 else b)
	if child != null:
		m.add_child(child)
	return m


static func panel(variation: String = "CardPanel", child: Control = null) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	if child != null:
		p.add_child(child)
	return p


static func spacer(horizontal: bool = true) -> Control:
	var c := Control.new()
	if horizontal:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func gap(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Rounded coloured pill with optional icon.
static func chip(text: String, color: Color = Palette.ACCENT, icon_name: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	var sb := ThemeBuilder.box(Color(color, 0.16), 100, Color(color, 0.55), 1, 12, 4)
	p.add_theme_stylebox_override("panel", sb)
	var row := hbox(6)
	if not icon_name.is_empty():
		row.add_child(icon(icon_name, 16, color))
	var l := label(text, "SmallLabel")
	l.add_theme_color_override("font_color", color.lightened(0.25))
	row.add_child(l)
	p.add_child(row)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func progress(value: float, color: Color = Palette.ACCENT, height: int = 8) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.0001
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_stylebox_override("fill", ThemeBuilder.box(color, 100, Color.TRANSPARENT, 0, 0, 0))
	return bar


static func center(child: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.add_child(child)
	return c


static func scroll(child: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	return s


## Standard screen header: back button + title (+ optional right side widget).
static func header(title: String, on_back: Callable, right: Control = null) -> HBoxContainer:
	var row := hbox(16)
	row.add_child(button("Back", "arrow_left", "GhostButton", on_back))
	var t := label(title, "HeadingLabel")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	if right != null:
		row.add_child(right)
	return row


static func format_time(seconds: float) -> String:
	var s := int(ceil(seconds))
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]
