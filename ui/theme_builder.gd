class_name ThemeBuilder
extends RefCounted
## Builds the game's Theme in code (fonts, style boxes, type variations).
## Type variations used by screens: TitleLabel, HeadingLabel, SubtitleLabel, MutedLabel, SmallLabel,
## AccentButton, GhostButton, DangerButton, CardPanel, CardPanelRaised, ChipPanel, HudPanel.

const FONT_REGULAR := "res://assets/fonts/Inter-Regular.ttf"
const FONT_MEDIUM := "res://assets/fonts/Inter-Medium.ttf"
const FONT_SEMIBOLD := "res://assets/fonts/Inter-SemiBold.ttf"
const FONT_BOLD := "res://assets/fonts/Inter-Bold.ttf"
const FONT_BLACK := "res://assets/fonts/Inter-Black.ttf"
const FONT_MONO := "res://assets/fonts/JetBrainsMono-Regular.ttf"

static var _cache: Theme


static func font(path: String) -> FontFile:
	return load(path) as FontFile


static func box(bg: Color, radius: int = 12, border: Color = Color.TRANSPARENT, border_w: int = 0,
		pad_h: int = 16, pad_v: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	sb.anti_aliasing = true
	sb.corner_detail = 8
	return sb


static func build() -> Theme:
	if _cache != null:
		return _cache
	var t := Theme.new()
	t.default_font = font(FONT_REGULAR)
	t.default_font_size = 18

	# ---- Labels
	t.set_color("font_color", "Label", Palette.TEXT)
	_variation(t, "TitleLabel", "Label", {"font": FONT_BLACK, "size": 54, "color": Palette.TEXT})
	_variation(t, "HeadingLabel", "Label", {"font": FONT_BOLD, "size": 28, "color": Palette.TEXT})
	_variation(t, "SubtitleLabel", "Label", {"font": FONT_SEMIBOLD, "size": 20, "color": Palette.TEXT})
	_variation(t, "MutedLabel", "Label", {"font": FONT_REGULAR, "size": 16, "color": Palette.MUTED})
	_variation(t, "SmallLabel", "Label", {"font": FONT_MEDIUM, "size": 13, "color": Palette.MUTED})
	_variation(t, "BigNumberLabel", "Label", {"font": FONT_BLACK, "size": 40, "color": Palette.TEXT})

	# ---- RichTextLabel (question text)
	t.set_font("normal_font", "RichTextLabel", font(FONT_MEDIUM))
	t.set_font("bold_font", "RichTextLabel", font(FONT_BOLD))
	t.set_font("mono_font", "RichTextLabel", font(FONT_MONO))
	t.set_font_size("normal_font_size", "RichTextLabel", 22)
	t.set_font_size("bold_font_size", "RichTextLabel", 22)
	t.set_font_size("mono_font_size", "RichTextLabel", 19)
	t.set_color("default_color", "RichTextLabel", Palette.TEXT)

	# ---- Buttons
	t.set_font("font", "Button", font(FONT_SEMIBOLD))
	t.set_font_size("font_size", "Button", 18)
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.TEXT)
	t.set_color("font_pressed_color", "Button", Palette.TEXT)
	t.set_color("font_focus_color", "Button", Palette.TEXT)
	t.set_color("font_disabled_color", "Button", Palette.FAINT)
	t.set_color("icon_normal_color", "Button", Palette.TEXT)
	t.set_constant("h_separation", "Button", 10)
	t.set_stylebox("normal", "Button", box(Palette.SURFACE_2, 12, Palette.BORDER, 1, 18, 10))
	t.set_stylebox("hover", "Button", box(Palette.SURFACE_3, 12, Palette.ACCENT, 1, 18, 10))
	t.set_stylebox("pressed", "Button", box(Palette.SURFACE, 12, Palette.ACCENT, 2, 18, 10))
	t.set_stylebox("focus", "Button", box(Color.TRANSPARENT, 12, Palette.ACCENT_2, 2, 18, 10))
	t.set_stylebox("disabled", "Button", box(Palette.BG_2, 12, Palette.SURFACE_2, 1, 18, 10))

	t.add_type("AccentButton")
	t.set_type_variation("AccentButton", "Button")
	t.set_font("font", "AccentButton", font(FONT_BOLD))
	t.set_color("font_color", "AccentButton", Color("1a1206"))
	t.set_color("font_hover_color", "AccentButton", Color("1a1206"))
	t.set_color("font_pressed_color", "AccentButton", Color("1a1206"))
	t.set_color("font_focus_color", "AccentButton", Color("1a1206"))
	t.set_color("icon_normal_color", "AccentButton", Color("1a1206"))
	t.set_color("icon_hover_color", "AccentButton", Color("1a1206"))
	t.set_stylebox("normal", "AccentButton", box(Palette.ACCENT, 12, Color.TRANSPARENT, 0, 22, 12))
	t.set_stylebox("hover", "AccentButton", box(Palette.ACCENT_2, 12, Color.TRANSPARENT, 0, 22, 12))
	t.set_stylebox("pressed", "AccentButton", box(Palette.ACCENT_DARK, 12, Color.TRANSPARENT, 0, 22, 12))

	t.add_type("GhostButton")
	t.set_type_variation("GhostButton", "Button")
	t.set_color("font_color", "GhostButton", Palette.MUTED)
	t.set_color("font_hover_color", "GhostButton", Palette.TEXT)
	t.set_color("icon_normal_color", "GhostButton", Palette.MUTED)
	t.set_color("icon_hover_color", "GhostButton", Palette.TEXT)
	t.set_stylebox("normal", "GhostButton", box(Color.TRANSPARENT, 10, Color.TRANSPARENT, 0, 12, 8))
	t.set_stylebox("hover", "GhostButton", box(Palette.SURFACE_2, 10, Color.TRANSPARENT, 0, 12, 8))
	t.set_stylebox("pressed", "GhostButton", box(Palette.SURFACE, 10, Color.TRANSPARENT, 0, 12, 8))

	t.add_type("DangerButton")
	t.set_type_variation("DangerButton", "Button")
	t.set_stylebox("normal", "DangerButton", box(Palette.ERROR.darkened(0.55), 12, Palette.ERROR, 1, 18, 10))
	t.set_stylebox("hover", "DangerButton", box(Palette.ERROR.darkened(0.4), 12, Palette.ERROR, 2, 18, 10))

	# ---- Panels
	t.set_stylebox("panel", "PanelContainer", box(Palette.SURFACE, 16, Palette.BORDER, 1, 20, 18))
	t.add_type("CardPanel")
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", box(Palette.SURFACE, 18, Palette.BORDER, 1, 24, 20))
	t.add_type("CardPanelRaised")
	t.set_type_variation("CardPanelRaised", "PanelContainer")
	var raised := box(Palette.SURFACE_2, 18, Palette.BORDER, 1, 24, 20)
	raised.shadow_color = Color(0, 0, 0, 0.35)
	raised.shadow_size = 18
	raised.shadow_offset = Vector2(0, 6)
	t.set_stylebox("panel", "CardPanelRaised", raised)
	t.add_type("ChipPanel")
	t.set_type_variation("ChipPanel", "PanelContainer")
	t.set_stylebox("panel", "ChipPanel", box(Palette.SURFACE_3, 100, Color.TRANSPARENT, 0, 12, 4))
	t.add_type("HudPanel")
	t.set_type_variation("HudPanel", "PanelContainer")
	t.set_stylebox("panel", "HudPanel", box(Color(Palette.BG_2, 0.85), 14, Palette.BORDER, 1, 18, 10))

	# ---- Progress bar
	t.set_stylebox("background", "ProgressBar", box(Palette.SURFACE_3, 100, Color.TRANSPARENT, 0, 0, 0))
	t.set_stylebox("fill", "ProgressBar", box(Palette.ACCENT, 100, Color.TRANSPARENT, 0, 0, 0))
	t.set_font_size("font_size", "ProgressBar", 12)
	t.set_color("font_color", "ProgressBar", Palette.TEXT)

	# ---- Sliders / checkboxes / option buttons
	t.set_stylebox("slider", "HSlider", box(Palette.SURFACE_3, 100, Color.TRANSPARENT, 0, 0, 3))
	t.set_stylebox("grabber_area", "HSlider", box(Palette.ACCENT, 100, Color.TRANSPARENT, 0, 0, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(Palette.ACCENT_2, 100, Color.TRANSPARENT, 0, 0, 3))
	t.set_font("font", "CheckButton", font(FONT_MEDIUM))
	t.set_font("font", "CheckBox", font(FONT_MEDIUM))
	t.set_font("font", "OptionButton", font(FONT_MEDIUM))
	for type in ["CheckButton", "CheckBox"]:
		t.set_stylebox("normal", type, box(Color.TRANSPARENT, 10, Color.TRANSPARENT, 0, 6, 6))
		t.set_stylebox("hover", type, box(Palette.SURFACE_2, 10, Color.TRANSPARENT, 0, 6, 6))
		t.set_stylebox("pressed", type, box(Color.TRANSPARENT, 10, Color.TRANSPARENT, 0, 6, 6))
		t.set_stylebox("hover_pressed", type, box(Palette.SURFACE_2, 10, Color.TRANSPARENT, 0, 6, 6))
		t.set_stylebox("focus", type, box(Color.TRANSPARENT, 10, Palette.ACCENT_2, 1, 6, 6))

	# ---- Popups / dialogs
	t.set_stylebox("panel", "PopupPanel", box(Palette.SURFACE_2, 14, Palette.BORDER, 1, 12, 12))
	t.set_stylebox("panel", "PopupMenu", box(Palette.SURFACE_2, 10, Palette.BORDER, 1, 8, 8))
	t.set_stylebox("hover", "PopupMenu", box(Palette.SURFACE_3, 8, Color.TRANSPARENT, 0, 8, 4))

	# ---- Scrollbars (slim)
	for type in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", type, box(Color.TRANSPARENT, 100, Color.TRANSPARENT, 0, 4, 4))
		t.set_stylebox("grabber", type, box(Palette.SURFACE_3, 100, Color.TRANSPARENT, 0, 4, 4))
		t.set_stylebox("grabber_highlight", type, box(Palette.BORDER, 100, Color.TRANSPARENT, 0, 4, 4))
		t.set_stylebox("grabber_pressed", type, box(Palette.ACCENT, 100, Color.TRANSPARENT, 0, 4, 4))

	# ---- Tooltip
	t.set_stylebox("panel", "TooltipPanel", box(Palette.SURFACE_3, 8, Palette.BORDER, 1, 10, 6))
	t.set_color("font_color", "TooltipLabel", Palette.TEXT)

	# ---- CodeEdit (question snippets)
	t.set_font("font", "CodeEdit", font(FONT_MONO))
	t.set_font_size("font_size", "CodeEdit", 16)
	t.set_color("font_color", "CodeEdit", Color("d7dcef"))
	t.set_color("font_readonly_color", "CodeEdit", Color("d7dcef"))
	t.set_color("background_color", "CodeEdit", Color("0c0e15"))
	t.set_color("line_number_color", "CodeEdit", Palette.FAINT)
	t.set_color("current_line_color", "CodeEdit", Color.TRANSPARENT)
	t.set_color("selection_color", "CodeEdit", Color(Palette.ACCENT, 0.25))
	t.set_stylebox("normal", "CodeEdit", box(Color("0c0e15"), 12, Palette.BORDER, 1, 14, 12))
	t.set_stylebox("read_only", "CodeEdit", box(Color("0c0e15"), 12, Palette.BORDER, 1, 14, 12))
	t.set_stylebox("focus", "CodeEdit", box(Color.TRANSPARENT, 12, Palette.BORDER, 1, 14, 12))

	_cache = t
	return t


static func _variation(t: Theme, name: String, base: String, cfg: Dictionary) -> void:
	t.add_type(name)
	t.set_type_variation(name, base)
	t.set_font("font", name, font(cfg.font))
	t.set_font_size("font_size", name, cfg.size)
	t.set_color("font_color", name, cfg.color)
