class_name Screen
extends Control
## Base class for all screens. Subclasses override build() and optionally on_back().

var params := {}
var root: VBoxContainer          # main content column inside safe margins


func setup(p: Dictionary) -> void:
	params = p


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := UI.margin(null, 40, 28, 40, 28)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	root = UI.vbox(18)
	m.add_child(root)
	build()


func build() -> void:
	pass


func on_back() -> void:
	Router.go("main_menu")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		on_back()


func main() -> Node:
	return get_tree().root.get_node_or_null("Main")
