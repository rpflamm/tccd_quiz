class_name FX
extends RefCounted
## "Juice" helpers built on Tweens and CPUParticles2D (works on Web/Compatibility).


static func motion_ok() -> bool:
	return not Settings.reduced_motion


## Scale pop from the centre of a control.
static func pop(node: Control, strength: float = 0.08, duration: float = 0.25) -> void:
	if not motion_ok() or not is_instance_valid(node):
		return
	node.pivot_offset = node.size / 2.0
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE * (1.0 + strength), duration * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.65).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Horizontal shake (wrong answer). Uses position offset and restores it.
static func shake(node: Control, strength: float = 12.0, duration: float = 0.35) -> void:
	if not Settings.screen_shake or not motion_ok() or not is_instance_valid(node):
		return
	var origin := node.position
	var tw := node.create_tween()
	var steps := 7
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		var dx := strength * falloff * (1.0 if i % 2 == 0 else -1.0)
		tw.tween_property(node, "position", origin + Vector2(dx, 0), duration / steps)
	tw.tween_property(node, "position", origin, duration / steps)


## Fade + slide in from below.
static func enter(node: Control, delay: float = 0.0, distance: float = 24.0, duration: float = 0.35) -> void:
	if not is_instance_valid(node):
		return
	if not motion_ok():
		node.modulate.a = 1.0
		return
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func():
		node.position.y += distance
		var t2 := node.create_tween().set_parallel()
		t2.tween_property(node, "modulate:a", 1.0, duration)
		t2.tween_property(node, "position:y", node.position.y - distance, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))


## Staggered enter for all children of a container (after layout).
static func stagger(container: Control, step: float = 0.05) -> void:
	if not motion_ok():
		return
	var i := 0
	for c in container.get_children():
		if c is Control:
			c.modulate.a = 0.0
			var tw := c.create_tween()
			tw.tween_interval(i * step)
			tw.tween_property(c, "modulate:a", 1.0, 0.3)
			i += 1


## Pulsing modulate (e.g. low timer).
static func pulse(node: CanvasItem, color: Color, duration: float = 0.5) -> Tween:
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "modulate", color, duration / 2.0)
	tw.tween_property(node, "modulate", Color.WHITE, duration / 2.0)
	return tw


## Number count-up on a Label.
static func count_up(lbl: Label, from: int, to: int, duration: float = 0.8, fmt: String = "%d") -> void:
	if not motion_ok():
		lbl.text = fmt % to
		return
	var tw := lbl.create_tween()
	tw.tween_method(func(v: float): lbl.text = fmt % int(round(v)), float(from), float(to), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Floating text that rises and fades (e.g. "+300").
static func float_text(parent: Control, text: String, at: Vector2, color: Color = Palette.ACCENT_2, size: int = 30) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = "HeadingLabel"
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 6)
	l.position = at
	l.z_index = 50
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", at.y - 70, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)


## Confetti burst at a position (global canvas coordinates of parent).
static func confetti(parent: Node, at: Vector2, colors: Array = [Palette.ACCENT, Palette.ACCENT_2, Palette.SUCCESS, Palette.INFO, Palette.PINK], amount: int = 40, spread: float = 180.0) -> void:
	if not motion_ok():
		return
	for c in colors:
		var p := CPUParticles2D.new()
		p.position = at
		p.one_shot = true
		p.emitting = false
		p.amount = maxi(amount / colors.size(), 4)
		p.lifetime = 1.2
		p.explosiveness = 0.95
		p.direction = Vector2(0, -1)
		p.spread = spread
		p.initial_velocity_min = 220.0
		p.initial_velocity_max = 520.0
		p.gravity = Vector2(0, 900)
		p.angular_velocity_min = -540.0
		p.angular_velocity_max = 540.0
		p.scale_amount_min = 5.0
		p.scale_amount_max = 9.0
		p.color = c
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 1, 1, 1))
		ramp.set_color(1, Color(1, 1, 1, 0))
		p.color_ramp = ramp
		p.z_index = 60
		parent.add_child(p)
		p.emitting = true
		p.finished.connect(p.queue_free)


## Short full-screen colour flash on a ColorRect overlay.
static func flash(overlay: ColorRect, color: Color, strength: float = 0.18, duration: float = 0.35) -> void:
	if not motion_ok() or not is_instance_valid(overlay):
		return
	overlay.color = Color(color, strength)
	var tw := overlay.create_tween()
	tw.tween_property(overlay, "color:a", 0.0, duration)
