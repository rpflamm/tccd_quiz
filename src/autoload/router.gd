extends Node
## Screen navigation with an animated wipe transition, plus toasts.
## Screens are scripts in res://scenes/screens/<name>.gd extending Screen.

const SCREEN_DIR := "res://scenes/screens/"

var host: Control                # set by Main
var _layer: CanvasLayer
var _wipe: ColorRect
var _toasts: VBoxContainer
var _busy := false
var current: Control
var current_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)

	_wipe = ColorRect.new()
	_wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://ui/shaders/transition.gdshader")
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("color", Palette.ACCENT)
	mat.set_shader_parameter("color_2", Palette.BG)
	_wipe.material = mat
	_wipe.visible = false
	_layer.add_child(_wipe)

	_toasts = VBoxContainer.new()
	_toasts.theme = ThemeBuilder.build()
	_toasts.anchor_left = 1.0
	_toasts.anchor_right = 1.0
	_toasts.offset_left = -400.0
	_toasts.offset_right = -24.0
	_toasts.offset_top = 104.0
	_toasts.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toasts.add_theme_constant_override("separation", 10)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_toasts)
	Profile.achievement_unlocked.connect(_on_achievement)


func go(screen_name: String, params: Dictionary = {}, animate: bool = true) -> void:
	if _busy or host == null:
		return
	var script: Script = load(SCREEN_DIR + screen_name + ".gd")
	if script == null:
		push_error("Unknown screen " + screen_name)
		return
	_busy = true
	if animate and not Settings.reduced_motion:
		Audio.play("whoosh", 1.0, -6.0)
		await _animate_wipe(0.0, 1.0)
	if is_instance_valid(current):
		current.queue_free()
	var screen: Control = script.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	if screen.has_method("setup"):
		screen.setup(params)
	host.add_child(screen)
	current = screen
	current_name = screen_name
	if animate and not Settings.reduced_motion:
		await _animate_wipe(1.0, 2.0)
	_wipe.visible = false
	_busy = false


func _animate_wipe(from: float, to: float) -> void:
	_wipe.visible = true
	var mat := _wipe.material as ShaderMaterial
	mat.set_shader_parameter("progress", from)
	var tw := create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("progress", v), from, to, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


## Small notification card at the top right.
func toast(title: String, text: String = "", icon_name: String = "star", color: Color = Palette.ACCENT, seconds: float = 3.2) -> void:
	var card := PanelContainer.new()
	var sb := ThemeBuilder.box(Palette.SURFACE_2, 14, color, 2, 16, 12)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 14
	card.add_theme_stylebox_override("panel", sb)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UI.hbox(12)
	row.add_child(UI.icon(icon_name, 34, color))
	var col := UI.vbox(2)
	var t := UI.label(title, "SubtitleLabel")
	col.add_child(t)
	if not text.is_empty():
		var d := UI.wrap_label(text, "SmallLabel")
		d.custom_minimum_size = Vector2(260, 0)
		col.add_child(d)
	row.add_child(col)
	card.add_child(row)
	card.modulate.a = 0.0
	_toasts.add_child(card)
	var tw := card.create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.25)
	tw.tween_interval(seconds)
	tw.tween_property(card, "modulate:a", 0.0, 0.4)
	tw.tween_callback(card.queue_free)


func _on_achievement(def: Dictionary) -> void:
	Audio.play("achievement")
	toast("Achievement unlocked!", "%s — %s" % [def.title, def.desc], def.get("icon", "trophy"), Palette.WARNING, 4.0)
