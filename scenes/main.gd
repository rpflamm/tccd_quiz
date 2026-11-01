extends Control
## Root of the game: animated background, screen host, flash overlay. Starts at the main menu.

var background: ColorRect
var host: Control
var flash: ColorRect


func _ready() -> void:
	_apply_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Layout.changed.connect(_on_layout_changed)

	background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://ui/shaders/background.gdshader")
	background.material = mat
	add_child(background)

	host = Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(host)

	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(0, 0, 0, 0)
	add_child(flash)

	get_viewport().size_changed.connect(_on_resize)
	_on_resize()

	Router.host = host
	Router.go("main_menu", {}, false)
	Audio.play_music("menu")


func _apply_theme() -> void:
	get_tree().root.theme = ThemeBuilder.build()
	theme = ThemeBuilder.build()


func _on_layout_changed(_mode: int) -> void:
	_apply_theme()
	Router.apply_layout()
	Router.reload()


func _on_resize() -> void:
	var mat := background.material as ShaderMaterial
	mat.set_shader_parameter("resolution", get_viewport_rect().size)


## 0..1 – background animates faster and glows stronger during streaks.
func set_energy(value: float) -> void:
	var mat := background.material as ShaderMaterial
	var current: Variant = mat.get_shader_parameter("energy")
	var from: float = float(current) if current != null else 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("energy", v), from, clampf(value, 0.0, 1.0), 0.6)


func flash_color(color: Color, strength: float = 0.16) -> void:
	FX.flash(flash, color, strength)


static func instance() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Main")
