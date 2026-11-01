extends Screen
## Audio, video and gameplay settings plus credits.


func build() -> void:
	root.add_child(UI.header("Settings", on_back))
	var cols := flow(pick(18, 12, 12))
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var left := UI.panel("CardPanel")
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lc := UI.vbox(14)
	lc.add_child(UI.label("Audio", "SubtitleLabel"))
	lc.add_child(_slider("Music", Settings.music_volume, func(v): Settings.music_volume = v; Settings.save()))
	lc.add_child(_slider("Sound effects", Settings.sfx_volume, func(v):
		Settings.sfx_volume = v
		Settings.save()
		Audio.play("correct")))
	lc.add_child(UI.gap(6))
	lc.add_child(UI.label("Display & motion", "SubtitleLabel"))
	if OS.get_name() != "Web":
		lc.add_child(_toggle("Fullscreen (F11)", Settings.fullscreen, func(v): Settings.fullscreen = v; Settings.save()))
	lc.add_child(_toggle("Screen shake on wrong answers", Settings.screen_shake, func(v): Settings.screen_shake = v; Settings.save()))
	lc.add_child(_toggle("Reduced motion (no animations, confetti or transitions)", Settings.reduced_motion, func(v): Settings.reduced_motion = v; Settings.save()))
	lc.add_child(UI.gap(6))
	lc.add_child(UI.label("Exam scoring", "SubtitleLabel"))
	lc.add_child(_toggle("Partial credit for multi-choice questions", Settings.scoring == "partial", func(v):
		Settings.scoring = "partial" if v else "all_or_nothing"
		Settings.save()))
	lc.add_child(UI.wrap_label("The pass/fail decision always counts fully correct answers (51 of 75). Partial credit only changes the displayed score percentage.", "SmallLabel"))
	left.add_child(lc)
	cols.add_child(left)

	var right := UI.panel("CardPanel")
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rc := UI.vbox(10)
	rc.add_child(UI.label("About", "SubtitleLabel"))
	rc.add_child(UI.wrap_label("TCCD Quizz is an unofficial practice tool for the TYPO3 CMS Certified Developer exam (v14 LTS). Questions follow the official syllabus but are not real exam questions. TYPO3 is a registered trademark of the TYPO3 Association; this project is not affiliated with the TYPO3 Association or TYPO3 GmbH.", "MutedLabel"))
	rc.add_child(UI.label("Questions: %d  ·  Syllabus skills: %d" % [QuestionBank.pool.size(), _skill_count()], "SmallLabel"))
	rc.add_child(UI.gap(6))
	rc.add_child(UI.label("Credits", "SubtitleLabel"))
	rc.add_child(UI.wrap_label("Engine: Godot 4.7 (MIT)  ·  Tests: GUT (MIT)\nFonts: Inter, JetBrains Mono (SIL OFL 1.1)\nIcons, sounds and music: generated for this project (tools/gen_icons.py, tools/gen_audio.py)\nSyllabus: TYPO3 Education Committee — CMS Certified Developer 14 LTS", "SmallLabel"))
	if not compact():
		rc.add_child(UI.spacer(false))
	rc.add_child(UI.label("Version %s" % ProjectSettings.get_setting("application/config/version", "dev"), "SmallLabel"))
	right.add_child(rc)
	cols.add_child(right)
	root.add_child(scroll_if_compact(cols))


func _skill_count() -> int:
	var n := 0
	for d in QuestionBank.pool.domains:
		n += d.skills.size()
	return n


func _slider(title: String, value: float, on_change: Callable) -> HBoxContainer:
	var row := UI.hbox(12)
	row.add_child(UI.icon("volume", 20, Palette.MUTED))
	var l := UI.label(title, "MutedLabel")
	l.custom_minimum_size = Vector2(pick(150, 130, 96), 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pct := UI.label("%d %%" % int(value * 100), "SmallLabel")
	pct.custom_minimum_size = Vector2(48, 0)
	s.value_changed.connect(func(v: float):
		pct.text = "%d %%" % int(v * 100))
	s.drag_ended.connect(func(_changed: bool): on_change.call(s.value))
	row.add_child(s)
	row.add_child(pct)
	return row


func _toggle(title: String, value: bool, on_change: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = title
	c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.button_pressed = value
	c.toggled.connect(func(v: bool):
		Audio.play("click")
		on_change.call(v))
	return c
