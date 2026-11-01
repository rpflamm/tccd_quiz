extends Screen
## Exam simulation setup: full exam or shorter variants, plus exam history.


func build() -> void:
	root.add_child(UI.header("Exam simulation", on_back))
	var content := UI.vbox(pick(18, 12, 12))
	content.add_child(UI.wrap_label("Questions are drawn from all 8 syllabus domains, weighted by the number of skills per domain. No feedback until the end — flag questions and come back to them, just like in the real exam.", "MutedLabel"))

	var row := flow(pick(16, 12, 10))
	row.add_child(_variant("Full exam", "75 questions · 90 minutes", "The real deal. Pass with 51 correct answers.", 75, 90, Palette.ACCENT, "exam"))
	row.add_child(_variant("Half exam", "38 questions · 45 minutes", "Same pace, half the time.", 38, 45, Palette.INFO, "clock"))
	row.add_child(_variant("Quick check", "15 questions · 18 minutes", "A short reality check during lunch.", 15, 18, Palette.TEAL, "bolt"))
	content.add_child(row)
	FX.stagger(row, 0.06)

	var hist := UI.panel("CardPanel")
	hist.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var col := UI.vbox(8)
	col.add_child(UI.label("Recent exams", "SubtitleLabel"))
	var list := UI.vbox(6)
	var history: Array = Profile.data.exam_history.duplicate()
	history.reverse()
	if history.is_empty():
		list.add_child(UI.label("No exams yet. Your results will show up here.", "MutedLabel"))
	for e in history.slice(0, 10):
		var r := UI.hbox(12)
		var ok: bool = e.get("passed", false)
		r.add_child(UI.icon("check" if ok else "cross", 18, Palette.SUCCESS if ok else Palette.ERROR))
		var date := Time.get_datetime_string_from_unix_time(int(e.get("time", 0)), true).substr(0, 16)
		var l := UI.label(date.substr(5) if portrait() else date, "MutedLabel")
		l.custom_minimum_size = Vector2(pick(170, 160, 0), 0)
		r.add_child(l)
		var rate := float(e.correct) / maxf(float(e.total), 1.0)
		r.add_child(UI.label("%d / %d  (%d %%)" % [int(e.correct), int(e.total), int(round(rate * 100))], "SubtitleLabel"))
		var bar := UI.progress(rate, Palette.SUCCESS if ok else Palette.ERROR, 8)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(bar)
		if not portrait():
			r.add_child(UI.label(UI.format_time(float(e.get("seconds", 0))), "SmallLabel"))
		list.add_child(r)
	if compact():
		col.add_child(list)
	else:
		col.add_child(UI.scroll(list))
	var scoring := "Scoring: all-or-nothing per question" if Settings.scoring == "all_or_nothing" else "Scoring: partial credit for multi-choice (see Settings)"
	col.add_child(UI.label(scoring, "SmallLabel"))
	hist.add_child(col)
	content.add_child(hist)
	root.add_child(scroll_if_compact(content))


func _variant(title: String, meta: String, desc: String, count: int, minutes: int, color: Color, icon_name: String) -> ClickCard:
	var card := ClickCard.new(color)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := UI.vbox(10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(UI.hbox(12, [ClickCard.icon_badge(icon_name, color, pick(52, 40, 40)), UI.label(title, "HeadingLabel")]))
	var m := UI.label(meta, "SubtitleLabel")
	m.add_theme_color_override("font_color", color.lightened(0.2))
	col.add_child(m)
	if not compact():
		col.add_child(UI.wrap_label(desc, "MutedLabel"))
	card.add_child(col)
	card.pressed.connect(func():
		var mode := ExamMode.new()
		mode.setup(QuestionBank.pool, Profile.data, null, {"count": count, "minutes": minutes, "scoring": Settings.scoring})
		Router.go("quiz", {"mode": mode}))
	return card
