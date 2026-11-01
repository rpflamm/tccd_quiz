class_name TapDetector
extends RefCounted
## Distinguishes a tap from a scroll/drag gesture for clickable cards inside ScrollContainers.
## The press is NOT accepted, so the event still reaches the ScrollContainer and drag-scrolling works.
## A tap fires on release when the pointer moved less than MAX_MOVE and no scroll started.

const MAX_MOVE := 14.0

var _pressed := false
var _moved := 0.0


## Feed every gui_input event. Returns true when a tap was completed.
func handle(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			_moved = 0.0
			return false
		var was_tap := _pressed and _moved < MAX_MOVE
		_pressed = false
		return was_tap
	if event is InputEventMouseMotion and _pressed:
		_moved += (event as InputEventMouseMotion).relative.length()
		if _moved >= MAX_MOVE:
			_pressed = false
	return false


## Call when the parent ScrollContainer starts scrolling (NOTIFICATION_SCROLL_BEGIN).
func cancel() -> void:
	_pressed = false


func is_pressed() -> bool:
	return _pressed
