extends Screen
## The quiz screen used by all modes. The QuizMode decides timers, lives, feedback and navigation.

enum Phase { COUNTDOWN, ANSWERING, FEEDBACK, PAUSED, OVER }

const STREAK_MILESTONES := [3, 5, 10, 15, 20, 25, 30, 40, 50]

var mode: QuizMode
var phase := Phase.COUNTDOWN
var _selected: Array = []                 # original answer indices
var _buttons: Array[AnswerButton] = []
var _last_tick_second := -1
var _rng := RandomNumberGenerator.new()

# HUD
var _progress_label: Label
var _timer_label: Label
var _timer_bar: TimerBar
var _lives_box: HBoxContainer
var _streak_chip: PanelContainer
var _streak_label: Label
var _score_label: Label

# content
var _scroll: ScrollContainer
var _card: PanelContainer
var _card_box: VBoxContainer
var _answers_box: VBoxContainer
var _feedback: PanelContainer
var _actions: HBoxContainer
var _submit_btn: Button
var _overlay: Control
var _nav_label: Label
var _flag_btn: Button


func setup(p: Dictionary) -> void:
	super.setup(p)
	mode = p.mode
	_rng.randomize()


func build() -> void:
	Audio.play_music("arcade" if mode is ArcadeMode else "menu")
	root.add_theme_constant_override("separation", 14)
	root.add_child(_build_hud())

	_scroll = UI.scroll(UI.vbox(14))
	var content: VBoxContainer = _scroll.get_child(0)
	_card = UI.panel("CardPanelRaised")
	_card_box = UI.vbox(16)
	_card.add_child(_card_box)
	content.add_child(_card)
	_feedback = UI.panel("CardPanel")
	_feedback.visible = false
	content.add_child(_feedback)
	root.add_child(_scroll)

	_actions = UI.hbox(10)
	root.add_child(_actions)
	_build_actions()

	if mode.question_count() == 0:
		Router.toast("No questions available", "Try another domain.", "cross", Palette.ERROR)
		phase = Phase.OVER
		return
	_show_question()
	if mode is ArcadeMode:
		_countdown()
	else:
		phase = Phase.ANSWERING


# ------------------------------------------------------------------ HUD

func _build_hud() -> Control:
	var hud := UI.panel("HudPanel")
	var row := UI.hbox(18)
	var icon_name := "exam" if mode is ExamMode else ("flame" if mode is ArcadeMode else ("brain" if mode is SrsMode else "target"))
	if mode.key == "daily":
		icon_name = "calendar"
	row.add_child(UI.icon(icon_name, 26, Palette.ACCENT))
	var title_col := UI.vbox(0)
	title_col.add_child(UI.label(mode.title, "SubtitleLabel"))
	_progress_label = UI.label("", "SmallLabel")
	title_col.add_child(_progress_label)
	row.add_child(title_col)

	var timer_col := UI.vbox(4)
	timer_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var timer_row := UI.hbox(8)
	timer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_row.add_child(UI.icon("clock", 18, Palette.MUTED))
	_timer_label = UI.label("", "SubtitleLabel")
	timer_row.add_child(_timer_label)
	timer_col.add_child(timer_row)
	_timer_bar = TimerBar.new()
	_timer_bar.custom_minimum_size = Vector2(260, 8)
	timer_col.add_child(_timer_bar)
	var has_timer := mode.total_time_limit() > 0.0 or mode.question_time_limit() > 0.0
	_timer_bar.visible = has_timer
	row.add_child(timer_col)

	_lives_box = UI.hbox(4)
	_lives_box.visible = mode.max_lives() > 0
	row.add_child(_lives_box)

	_streak_label = UI.label("", "SubtitleLabel")
	_streak_chip = UI.panel("ChipPanel", UI.hbox(6, [UI.icon("flame", 18, Palette.WARNING), _streak_label]))
	_streak_chip.visible = mode.instant_feedback()
	row.add_child(_streak_chip)

	_score_label = UI.label("", "HeadingLabel")
	_score_label.custom_minimum_size = Vector2(90, 0)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_score_label.visible = mode is ArcadeMode
	row.add_child(_score_label)

	row.add_child(UI.button("", "cross", "GhostButton", on_back))
	hud.add_child(row)
	return hud


func _update_hud() -> void:
	if mode is ExamMode:
		_progress_label.text = "Question %d / %d  ·  %d answered" % [mode.index + 1, mode.question_count(), mode.answered_count()]
	elif mode.is_endless():
		_progress_label.text = "Question %d  ·  %d correct" % [mode.index + 1, mode.correct_total]
	else:
		_progress_label.text = "Question %d / %d" % [mode.index + 1, mode.question_count()]
	if mode.max_lives() > 0:
		for c in _lives_box.get_children():
			c.queue_free()
		for i in mode.max_lives():
			var alive := i < mode.lives()
			_lives_box.add_child(UI.icon("heart" if alive else "heart_empty", 26, Palette.ERROR if alive else Palette.FAINT))
	_streak_label.text = "%d" % mode.streak
	if mode is ArcadeMode:
		_score_label.text = str(mode.score)
		_streak_label.text = "%d  ×%d" % [mode.streak, (mode as ArcadeMode).multiplier()]
	_update_timer()


func _update_timer() -> void:
	if mode.total_time_limit() > 0.0:
		var left := mode.time_left()
		_timer_label.text = UI.format_time(left)
		_timer_bar.fraction = left / mode.total_time_limit()
		_timer_bar.low_threshold = 0.1
	elif mode.question_time_limit() > 0.0:
		var left := mode.question_time_left()
		_timer_label.text = "%d s" % int(ceil(left))
		_timer_bar.fraction = left / mode.question_time_limit()
		_timer_bar.low_threshold = 0.3
	else:
		_timer_label.text = UI.format_time(mode.elapsed)


# ------------------------------------------------------------------ question

func _show_question() -> void:
	var q := mode.current()
	if q == null:
		return
	for c in _card_box.get_children():
		c.queue_free()
	_feedback.visible = false
	_buttons.clear()
	_selected = []
	if mode.is_answered():
		_selected = mode.selections[mode.index].duplicate()

	var meta := UI.hbox(10)
	var dcolor := Palette.domain_color(q.domain)
	meta.add_child(UI.chip(QuestionBank.pool.domain_name(q.domain), dcolor, Palette.domain_icon(q.domain)))
	var skill := UI.label(QuestionBank.pool.skill_name(q.domain, q.skill), "SmallLabel")
	skill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	skill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meta.add_child(skill)
	if q.tags.has("breaking-change"):
		meta.add_child(UI.chip("v14 change", Palette.PINK, "bolt"))
	meta.add_child(_difficulty_dots(q.difficulty))
	_card_box.add_child(meta)

	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.text = TextFormat.inline_code(q.text)
	_card_box.add_child(text)

	if q.has_code():
		_card_box.add_child(CodeView.new(q.code_src, q.code_lang))

	var hint_text := "Choose %d answers" % q.correct_count() if q.is_multi() else "Choose 1 answer"
	var hint := UI.chip(hint_text, Palette.INFO if q.is_multi() else Palette.FAINT, "check")
	hint.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_card_box.add_child(hint)

	_answers_box = UI.vbox(10)
	var order := mode.display_order()
	for display_i in order.size():
		var original: int = order[display_i]
		var b := AnswerButton.new(q.answers[original], display_i + 1, original)
		b.pressed.connect(_on_answer_pressed)
		_answers_box.add_child(b)
		_buttons.append(b)
	_card_box.add_child(_answers_box)
	_refresh_selection_states()

	if mode.instant_feedback() and mode.is_answered():
		_reveal_states()
	_update_actions()
	_update_hud()
	_scroll.scroll_vertical = 0
	FX.enter(_card, 0.0, 18.0, 0.3)
	_last_tick_second = -1


func _difficulty_dots(level: int) -> HBoxContainer:
	var box := UI.hbox(4)
	box.tooltip_text = ["", "Basic", "Applied", "Tricky"][level]
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	for i in 3:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.color = Palette.ACCENT if i < level else Palette.SURFACE_3
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(dot)
	return box


func _refresh_selection_states() -> void:
	for b in _buttons:
		b.set_state(AnswerButton.State.SELECTED if _selected.has(b.original_index) else AnswerButton.State.NORMAL)


func _on_answer_pressed(b: AnswerButton) -> void:
	if phase != Phase.ANSWERING:
		return
	var q := mode.current()
	if q.is_multi():
		if _selected.has(b.original_index):
			_selected.erase(b.original_index)
		else:
			_selected.append(b.original_index)
	else:
		_selected = [b.original_index]
	Audio.play("select", 1.0 + _selected.size() * 0.05)
	_refresh_selection_states()
	FX.pop(b, 0.03, 0.18)
	if mode is ExamMode:
		mode.submit(_selected)
		_update_hud()
		_update_actions()
	elif not q.is_multi():
		_submit()
	else:
		_update_actions()


func _submit() -> void:
	if phase != Phase.ANSWERING or _selected.is_empty():
		return
	var outcome := mode.submit(_selected)
	if outcome.is_empty():
		return
	_after_answer(outcome)


func _after_answer(outcome: Dictionary) -> void:
	phase = Phase.FEEDBACK
	var q := mode.current()
	var ok: bool = outcome.get("correct", false)
	_reveal_states()
	var m := main()
	if ok:
		var combo_pitch := 1.0 + minf(mode.streak, 10) * 0.04
		Audio.play("correct", combo_pitch)
		FX.pop(_card, 0.025, 0.3)
		var target := _first_correct_button()
		if target != null:
			FX.confetti(self, target.global_position + Vector2(target.size.x * 0.85, target.size.y / 2.0), [Palette.SUCCESS, Palette.ACCENT, Palette.ACCENT_2, Palette.INFO], 28, 120.0)
			if outcome.get("points", 0) > 0 and mode is ArcadeMode:
				FX.float_text(self, "+%d" % outcome.points, target.global_position + Vector2(target.size.x * 0.7, -10))
		if m:
			m.flash_color(Palette.SUCCESS, 0.08)
		if mode.streak in STREAK_MILESTONES:
			_streak_banner(mode.streak)
	else:
		Audio.play("wrong")
		if mode.max_lives() > 0:
			Audio.play("heart_lost", 1.0, -3.0)
		FX.shake(_card, 14.0)
		if m:
			m.flash_color(Palette.ERROR, 0.14)
	if m:
		m.set_energy(minf(mode.streak / 10.0, 1.0))
	_update_hud()
	if mode.max_lives() > 0 and not ok:
		FX.pop(_lives_box, 0.2, 0.35)
	_show_feedback(q, ok, outcome)
	_update_actions()


func _first_correct_button() -> AnswerButton:
	for b in _buttons:
		if mode.current().correct.has(b.original_index):
			return b
	return null


func _reveal_states() -> void:
	var q := mode.current()
	var sel: Array = mode.selections.get(mode.index, [])
	for b in _buttons:
		var is_right := q.correct.has(b.original_index)
		var picked := sel.has(b.original_index)
		if is_right and picked:
			b.set_state(AnswerButton.State.CORRECT)
		elif picked:
			b.set_state(AnswerButton.State.WRONG)
		elif is_right:
			b.set_state(AnswerButton.State.MISSED)
		else:
			b.set_state(AnswerButton.State.DIMMED)
		b.set_interactive(false)


func _show_feedback(q: Question, ok: bool, outcome: Dictionary) -> void:
	for c in _feedback.get_children():
		c.queue_free()
	var color := Palette.SUCCESS if ok else Palette.ERROR
	_feedback.add_theme_stylebox_override("panel", ThemeBuilder.box(Color(color, 0.08), 18, Color(color, 0.6), 2, 24, 18))
	var col := UI.vbox(10)
	var head := UI.hbox(10)
	head.add_child(UI.icon("check" if ok else ("clock" if outcome.get("timeout", false) else "cross"), 26, color))
	var title := "Correct!" if ok else ("Time's up!" if outcome.get("timeout", false) else "Not quite.")
	if ok and outcome.get("points", 0) > 0 and mode is ArcadeMode:
		title += "   +%d" % outcome.points
	var t := UI.label(title, "HeadingLabel")
	t.add_theme_color_override("font_color", color)
	head.add_child(t)
	head.add_child(UI.spacer())
	if outcome.get("xp", 0) > 0:
		head.add_child(UI.chip("+%d XP" % outcome.xp, Palette.ACCENT_2, "star"))
	col.add_child(head)
	var expl := RichTextLabel.new()
	expl.bbcode_enabled = true
	expl.fit_content = true
	expl.scroll_active = false
	expl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	expl.add_theme_font_size_override("normal_font_size", 18)
	expl.add_theme_font_size_override("mono_font_size", 16)
	expl.text = TextFormat.inline_code(q.explanation)
	col.add_child(expl)
	var row := UI.hbox(10)
	if not q.doc_url.is_empty():
		var doc := UI.button("Read the docs", "external", "GhostButton", func(): OS.shell_open(q.doc_url))
		doc.tooltip_text = q.doc_url
		row.add_child(doc)
	col.add_child(row)
	_feedback.add_child(col)
	_feedback.visible = true
	FX.enter(_feedback, 0.05, 16.0, 0.3)
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		_scroll.ensure_control_visible(_feedback)


func _streak_banner(n: int) -> void:
	Audio.play("streak", 1.0 + minf(n, 30) * 0.01)
	var texts := {3: "Nice streak!", 5: "On fire!", 10: "Unstoppable!", 15: "Cache hit!", 20: "Core Merger mode!", 25: "Legendary!"}
	var l := UI.label("%d in a row — %s" % [n, texts.get(n, "Keep going!")], "TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_size_override("font_size", 44)
	l.add_theme_color_override("font_color", Palette.ACCENT_2)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("outline_size", 10)
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 70
	add_child(l)
	l.position = (size - l.get_combined_minimum_size()) / 2.0
	l.pivot_offset = l.get_combined_minimum_size() / 2.0
	l.scale = Vector2(0.4, 0.4)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)
	FX.confetti(self, Vector2(size.x / 2.0, size.y * 0.55), [Palette.ACCENT, Palette.ACCENT_2, Palette.WARNING, Palette.PINK], 60, 160.0)


# ------------------------------------------------------------------ actions

func _build_actions() -> void:
	for c in _actions.get_children():
		c.queue_free()
	if mode is ExamMode:
		_actions.add_child(UI.button("Previous", "arrow_left", "", _prev))
		_flag_btn = UI.button("Flag", "flag", "", _toggle_flag)
		_actions.add_child(_flag_btn)
		_actions.add_child(UI.button("Overview", "grid", "", _show_overview))
		_actions.add_child(UI.spacer())
		_nav_label = UI.label("", "SmallLabel")
		_nav_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_actions.add_child(_nav_label)
		_actions.add_child(UI.button("Finish exam", "check", "DangerButton", _confirm_finish))
		_submit_btn = UI.button("Next", "arrow_right", "AccentButton", _next)
		_actions.add_child(_submit_btn)
	else:
		var hint := UI.label("Keys: 1–6 select · Enter confirm · Esc quit", "SmallLabel")
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_actions.add_child(hint)
		_actions.add_child(UI.spacer())
		_submit_btn = UI.button("Submit", "check", "AccentButton", _on_primary)
		_submit_btn.custom_minimum_size = Vector2(190, 0)
		_actions.add_child(_submit_btn)


func _update_actions() -> void:
	if mode is ExamMode:
		_submit_btn.disabled = mode.index >= mode.question_count() - 1
		_flag_btn.text = "Unflag" if mode.flags.has(mode.index) else "Flag"
		_nav_label.text = "%d flagged · %d open" % [mode.flags.size(), mode.question_count() - mode.answered_count()]
		return
	var q := mode.current()
	if phase == Phase.FEEDBACK or (q != null and mode.is_answered()):
		_submit_btn.text = "Continue"
		_submit_btn.icon = UI.icon_texture("arrow_right")
		_submit_btn.disabled = false
		_submit_btn.visible = true
		_submit_btn.grab_focus()
	else:
		_submit_btn.text = "Submit"
		_submit_btn.icon = UI.icon_texture("check")
		_submit_btn.visible = q != null and q.is_multi()
		_submit_btn.disabled = _selected.is_empty()


func _on_primary() -> void:
	if phase == Phase.FEEDBACK:
		_continue()
	elif phase == Phase.ANSWERING:
		_submit()


func _continue() -> void:
	if phase != Phase.FEEDBACK:
		return
	if not mode.advance():
		_finish()
		return
	phase = Phase.ANSWERING
	_show_question()


func _prev() -> void:
	if mode.index > 0:
		mode.goto(mode.index - 1)
		_show_question()


func _next() -> void:
	if mode.index < mode.question_count() - 1:
		mode.goto(mode.index + 1)
		_show_question()


func _toggle_flag() -> void:
	mode.toggle_flag()
	Audio.play("flag")
	_update_actions()


# ------------------------------------------------------------------ exam overview / dialogs

func _show_overview() -> void:
	var grid := GridContainer.new()
	grid.columns = 15
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for i in mode.question_count():
		var b := Button.new()
		b.text = str(i + 1)
		b.custom_minimum_size = Vector2(52, 40)
		b.focus_mode = Control.FOCUS_NONE
		var bg := Palette.SURFACE_2
		var border := Palette.BORDER
		if mode.is_answered(i):
			bg = Color(Palette.INFO, 0.3)
		if mode.flags.has(i):
			border = Palette.WARNING
		if i == mode.index:
			border = Palette.ACCENT
		b.add_theme_stylebox_override("normal", ThemeBuilder.box(bg, 8, border, 2, 4, 4))
		b.add_theme_stylebox_override("hover", ThemeBuilder.box(bg.lightened(0.15), 8, Palette.ACCENT, 2, 4, 4))
		b.add_theme_font_size_override("font_size", 15)
		var idx := i
		b.pressed.connect(func():
			_close_overlay()
			mode.goto(idx)
			_show_question())
		grid.add_child(b)
	var legend := UI.hbox(18, [
		UI.chip("answered", Palette.INFO), UI.chip("flagged", Palette.WARNING), UI.chip("current", Palette.ACCENT)])
	_open_overlay("Exam overview", [legend, grid], [UI.button("Close", "cross", "", _close_overlay)])


func _confirm_finish() -> void:
	var open := mode.question_count() - mode.answered_count()
	var msg := "You answered %d of %d questions." % [mode.answered_count(), mode.question_count()]
	if open > 0:
		msg += "  %d are still open and will count as wrong." % open
	if mode.flags.size() > 0:
		msg += "  %d flagged for review." % mode.flags.size()
	_open_overlay("Finish the exam?", [UI.wrap_label(msg, "MutedLabel")], [
		UI.button("Keep going", "arrow_left", "", _close_overlay),
		UI.button("Finish & see results", "check", "AccentButton", func():
			_close_overlay()
			_finish()),
	])


func on_back() -> void:
	if _overlay != null:
		_close_overlay()
		return
	if phase == Phase.OVER:
		Router.go("main_menu")
		return
	_open_overlay("Leave this run?", [UI.wrap_label(
		"Answers you already gave in practice, arcade and spaced repetition are saved. An unfinished exam is discarded.", "MutedLabel")], [
		UI.button("Resume", "play", "AccentButton", _close_overlay),
		UI.button("Quit to menu", "home", "DangerButton", func():
			Profile.save()
			Router.go("main_menu")),
	])


func _open_overlay(title: String, body: Array, buttons: Array) -> void:
	_close_overlay()
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.z_index = 80
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var card := UI.panel("CardPanelRaised")
	card.custom_minimum_size = Vector2(560, 0)
	var col := UI.vbox(16)
	col.add_child(UI.label(title, "HeadingLabel"))
	for b in body:
		col.add_child(b)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	for b in buttons:
		row.add_child(b)
	col.add_child(row)
	card.add_child(col)
	center.add_child(card)
	_overlay.add_child(center)
	add_child(_overlay)
	FX.pop(card, 0.04, 0.25)
	if phase in [Phase.ANSWERING, Phase.FEEDBACK, Phase.COUNTDOWN]:
		_overlay.set_meta("resume_phase", phase)
		phase = Phase.PAUSED
	if buttons.size() > 0:
		(buttons[buttons.size() - 1] as Control).grab_focus()


func _close_overlay() -> void:
	if _overlay == null:
		return
	if phase == Phase.PAUSED and _overlay.has_meta("resume_phase"):
		phase = _overlay.get_meta("resume_phase")
	_overlay.queue_free()
	_overlay = null


# ------------------------------------------------------------------ timing & input

func _countdown() -> void:
	phase = Phase.COUNTDOWN
	_card.modulate.a = 0.0
	var l := UI.label("", "TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_size_override("font_size", 120)
	l.add_theme_color_override("font_color", Palette.ACCENT)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	for word in ["3", "2", "1", "GO!"]:
		while phase == Phase.PAUSED:
			await get_tree().process_frame
		l.text = word
		Audio.play("go" if word == "GO!" else "count")
		l.pivot_offset = size / 2.0
		l.scale = Vector2(1.4, 1.4)
		l.modulate.a = 1.0
		var tw := l.create_tween().set_parallel()
		tw.tween_property(l, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "modulate:a", 0.25, 0.6)
		await get_tree().create_timer(0.6).timeout
		if not is_inside_tree():
			return
	l.queue_free()
	_card.modulate.a = 1.0
	FX.enter(_card, 0.0, 18.0, 0.25)
	if phase == Phase.COUNTDOWN:
		phase = Phase.ANSWERING
	elif phase == Phase.PAUSED and _overlay != null:
		_overlay.set_meta("resume_phase", Phase.ANSWERING)


func _process(delta: float) -> void:
	if phase != Phase.ANSWERING:
		return
	var event := mode.tick(delta)
	_update_timer()
	if mode.question_time_limit() > 0.0:
		var left := int(ceil(mode.question_time_left()))
		if left <= 5 and left != _last_tick_second and left > 0:
			_last_tick_second = left
			Audio.play("tick", 1.0 + (5 - left) * 0.08)
	elif mode.total_time_limit() > 0.0:
		var left_total := int(ceil(mode.time_left()))
		if left_total <= 10 and left_total != _last_tick_second and left_total > 0:
			_last_tick_second = left_total
			Audio.play("tick")
	match event:
		"question_timeout":
			_selected = []
			_after_answer(mode.timeout())
		"time_up":
			Router.toast("Time is up!", "The exam has been submitted.", "clock", Palette.WARNING)
			_finish()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		on_back()
		return
	if _overlay != null or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_6:
		var i := key - KEY_1
		if i < _buttons.size():
			_on_answer_pressed(_buttons[i])
			get_viewport().set_input_as_handled()
	elif key == KEY_ENTER or key == KEY_KP_ENTER or key == KEY_SPACE:
		if mode is ExamMode:
			_next()
		else:
			_on_primary()
		get_viewport().set_input_as_handled()
	elif mode is ExamMode:
		match key:
			KEY_F:
				_toggle_flag()
			KEY_LEFT:
				_prev()
			KEY_RIGHT:
				_next()


# ------------------------------------------------------------------ end

func _finish() -> void:
	if phase == Phase.OVER:
		return
	phase = Phase.OVER
	var old_xp := Profile.data.xp - mode.xp_gained
	mode.finish()
	Profile.save()
	var m := main()
	if m:
		m.set_energy(0.0)
	if mode is ArcadeMode and mode.max_lives() > 0 and mode.lives() <= 0:
		Audio.play("gameover")
		await get_tree().create_timer(0.9).timeout
	Router.go("results", {"mode": mode, "old_xp": old_xp})
