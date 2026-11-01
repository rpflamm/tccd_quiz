class_name Screen
extends Control
## Base class for all screens. Subclasses override build() and optionally on_back().
## Layout helpers: portrait()/compact() and columns() pick values for phone layouts.

var params := {}
var root: VBoxContainer          # main content column inside safe margins


func setup(p: Dictionary) -> void:
	params = p


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m: MarginContainer
	if portrait():
		m = UI.margin(null, 14, 14, 14, 14)
	elif compact():
		m = UI.margin(null, 22, 14, 22, 14)
	else:
		m = UI.margin(null, 40, 28, 40, 28)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	root = UI.vbox(12 if compact() else 18)
	m.add_child(root)
	build()


func build() -> void:
	pass


func on_back() -> void:
	Router.go("main_menu")


func portrait() -> bool:
	return Layout.is_portrait()


func compact() -> bool:
	return Layout.is_compact()


## Picks a value per layout: desktop / compact landscape / portrait.
func pick(desktop: Variant, compact_value: Variant, portrait_value: Variant) -> Variant:
	if portrait():
		return portrait_value
	if compact():
		return compact_value
	return desktop


## Wraps content in a scroll container on phones so nothing gets cut off.
func scroll_if_compact(content: Control) -> Control:
	if compact():
		return UI.scroll(content)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return content


## Row on desktop, column in portrait.
func flow(separation: int = 16) -> BoxContainer:
	return UI.vbox(separation) if portrait() else UI.hbox(separation)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		on_back()


func main() -> Node:
	return get_tree().root.get_node_or_null("Main")
