extends Node
## Responsive layout: picks a layout mode from the window size and adapts the content scale so that
## text stays readable on phones. Screens read `Layout.mode` and rebuild when `changed` fires.
##
##   DESKTOP    – landscape, enough height: logical canvas 1280×720 (original design)
##   COMPACT    – landscape but low (phones held sideways, small windows): logical height 520
##   PORTRAIT   – taller than wide (phones upright): logical width 460, single-column layouts

signal changed(mode: int)

enum Mode { DESKTOP, COMPACT, PORTRAIT }

const DESKTOP_SIZE := Vector2(1280, 720)
const COMPACT_HEIGHT := 520.0
const PORTRAIT_WIDTH := 460.0
## Below this logical (CSS) height a landscape window counts as compact.
const COMPACT_BELOW_HEIGHT := 640.0

var mode := Mode.DESKTOP
var touch := false
var _pending := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch = OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios") \
		or (DisplayServer.get_name() != "headless" and DisplayServer.is_touchscreen_available())
	get_tree().root.size_changed.connect(_on_size_changed)
	_apply(true)


func is_portrait() -> bool:
	return mode == Mode.PORTRAIT


func is_compact() -> bool:
	return mode != Mode.DESKTOP


## Window size in logical (CSS) pixels.
func css_size() -> Vector2:
	if OS.has_feature("web"):
		var w: Variant = JavaScriptBridge.eval("window.innerWidth", true)
		var h: Variant = JavaScriptBridge.eval("window.innerHeight", true)
		if w != null and h != null and float(w) > 0.0:
			return Vector2(float(w), float(h))
	var px := Vector2(get_tree().root.size)
	var scale := 1.0
	if DisplayServer.get_name() != "headless":
		scale = maxf(DisplayServer.screen_get_scale(), 1.0)
	return px / scale


func _on_size_changed() -> void:
	# Debounce: rotation and window dragging fire many events.
	if _pending:
		return
	_pending = true
	await get_tree().create_timer(0.15).timeout
	_pending = false
	_apply(false)


func _apply(initial: bool) -> void:
	var css := css_size()
	if css.x <= 0.0 or css.y <= 0.0:
		return
	var new_mode := Mode.DESKTOP
	if css.y > css.x:
		new_mode = Mode.PORTRAIT
	elif css.y < COMPACT_BELOW_HEIGHT:
		new_mode = Mode.COMPACT
	var root := get_tree().root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	match new_mode:
		Mode.DESKTOP:
			root.content_scale_size = Vector2i(DESKTOP_SIZE)
		Mode.COMPACT:
			root.content_scale_size = Vector2i(int(round(COMPACT_HEIGHT * css.x / css.y)), int(COMPACT_HEIGHT))
		Mode.PORTRAIT:
			root.content_scale_size = Vector2i(int(PORTRAIT_WIDTH), int(round(PORTRAIT_WIDTH * css.y / css.x)))
	if new_mode != mode or initial:
		mode = new_mode
		if not initial:
			changed.emit(mode)
