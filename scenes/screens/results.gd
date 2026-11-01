extends Screen
## Results after a run: headline, stat tiles, XP/rank progress, per-domain breakdown.

var mode: QuizMode
var result := {}
var old_xp := 0


func setup(p: Dictionary) -> void:
	super.setup(p)
	mode = p.mode
	result = mode.result()
	old_xp = int(p.get("old_xp", Profile.data.xp))


func build() -> void:
	Audio.play_music("menu")
	var total: int = maxi(int(result.total), 1)
	var correct: int = int(result.correct)
	var accuracy := float(correct) / float(total)

	# ---- headline
	var head := UI.vbox(4)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	var headline := ""
	var color := Palette.ACCENT
	var sub := ""
	if result.has_pass_mark:
		var exam := mode as ExamMode
		headline = "PASSED" if result.passed else "NOT PASSED"
		color = Palette.SUCCESS if result.passed else Palette.ERROR
		sub = "%d of %d correct  ·  pass mark %d  ·  %s" % [correct, total, exam.pass_mark(), UI.format_time(result.seconds)]
	elif mode is ArcadeMode and mode.key == "arcade":
		headline = "GAME OVER"
		color = Palette.ACCENT
		sub = "%d questions survived" % correct
	else:
		headline = "ROUND COMPLETE"
		color = Palette.INFO if accuracy < 0.7 else Palette.SUCCESS
		sub = "%d of %d correct" % [correct, total]
	var h := UI.label(headline, "TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	h.add_theme_color_override("font_color", color)
	head.add_child(h)
	head.add_child(UI.label(sub, "MutedLabel", HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(head)

	# ---- tiles
	var tiles := UI.hbox(14)
	tiles.alignment = BoxContainer.ALIGNMENT_CENTER
	if mode is ArcadeMode:
		tiles.add_child(_tile("Score", int(result.score), "%d", "trophy", Palette.ACCENT_2))
	tiles.add_child(_tile("Accuracy", int(round(accuracy * 100)), "%d %%", "target", color))
	tiles.add_child(_tile("Correct", correct, "%d / " + str(total), "check", Palette.SUCCESS))
	if mode.instant_feedback():
		tiles.add_child(_tile("Best streak", int(result.best_streak), "%d", "flame", Palette.WARNING))
	tiles.add_child(_tile("XP gained", int(result.xp), "+%d", "star", Palette.ACCENT))
	root.add_child(tiles)

	if result.new_highscore and int(result.score) > 0 and mode is ArcadeMode:
		var hs := UI.chip("NEW HIGHSCORE!", Palette.WARNING, "trophy")
		hs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		root.add_child(hs)
		FX.pulse(hs, Color(1.3, 1.2, 0.8))

	# ---- body: rank progress + domains
	var body := UI.hbox(18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_rank_card())
	body.add_child(_domain_card())
	root.add_child(body)

	# ---- buttons
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.button("Main menu", "home", "", func(): Router.go("main_menu")))
	if result.total > 0:
		row.add_child(UI.button("Review answers", "book", "", func(): Router.go("review", {"mode": mode})))
	var again := UI.button("Play again", "refresh", "AccentButton", _play_again)
	row.add_child(again)
	root.add_child(row)
	again.grab_focus()

	if not params.get("revisit", false):
		_celebrate(color)
		Profile.notify_unlocked(mode.unlocked)


func _tile(title: String, value: int, fmt: String, icon_name: String, color: Color) -> PanelContainer:
	var card := UI.panel("CardPanel")
	card.custom_minimum_size = Vector2(190, 0)
	var col := UI.vbox(2)
	var r := UI.hbox(8, [UI.icon(icon_name, 18, color), UI.label(title, "SmallLabel")])
	col.add_child(r)
	var v := UI.label(fmt % 0, "BigNumberLabel")
	v.add_theme_color_override("font_color", color)
	col.add_child(v)
	card.add_child(col)
	FX.count_up(v, 0, value, 0.9, fmt)
	return card


func _rank_card() -> PanelContainer:
	var p := Profile.data
	var card := UI.panel("CardPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 0.8
	var col := UI.vbox(10)
	col.add_child(UI.label("Rank", "SmallLabel"))
	var rank_label := UI.label(Ranks.title_for(old_xp), "HeadingLabel")
	col.add_child(rank_label)
	var bar := UI.progress(Ranks.progress(old_xp), Palette.ACCENT, 12)
	col.add_child(bar)
	var xp_label := UI.label("%d XP" % old_xp, "MutedLabel")
	col.add_child(xp_label)
	var leveled := Ranks.level_for(p.xp) > Ranks.level_for(old_xp)
	var tw := create_tween()
	tw.tween_interval(0.5)
	if leveled:
		tw.tween_property(bar, "value", 1.0, 0.6)
		tw.tween_callback(func():
			rank_label.text = Ranks.title_for(p.xp)
			bar.value = 0.0
			Audio.play("levelup")
			FX.pop(rank_label, 0.25, 0.5)
			FX.confetti(self, rank_label.global_position + Vector2(120, 20), [Palette.ACCENT, Palette.ACCENT_2, Palette.WARNING], 60)
			Router.toast("Rank up!", "You are now: " + Ranks.title_for(p.xp), "star", Palette.ACCENT, 3.5))
	tw.tween_property(bar, "value", Ranks.progress(p.xp), 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(v: float): xp_label.text = "%d XP  ·  next rank at %d" % [int(v), Ranks.next_xp(p.xp)], float(old_xp), float(p.xp), 0.8)
	col.add_child(UI.gap(8))
	if mode.key == "daily":
		col.add_child(UI.hbox(8, [UI.icon("flame", 20, Palette.WARNING), UI.label("Daily streak: %d day(s)" % int(p.daily.streak), "SubtitleLabel")]))
	if mode is ArcadeMode and mode.key == "arcade":
		col.add_child(UI.label("Highscore: %d" % p.highscore("arcade"), "SubtitleLabel"))
	if mode is ExamMode:
		col.add_child(UI.wrap_label("Real exam: 75 questions in 90 minutes, 51 correct answers needed (≈ 68 %).", "SmallLabel"))
	card.add_child(col)
	return card


func _domain_card() -> PanelContainer:
	var card := UI.panel("CardPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := UI.vbox(10)
	col.add_child(UI.label("Per domain", "SmallLabel"))
	var per: Dictionary = result.per_domain
	var list := UI.vbox(10)
	var weakest := ""
	var weakest_rate := 2.0
	for d in QuestionBank.pool.domains:
		if not per.has(d.id):
			continue
		var s: Dictionary = per[d.id]
		var rate := float(s.correct) / maxf(float(s.total), 1.0)
		if rate < weakest_rate and int(s.total) >= 2:
			weakest_rate = rate
			weakest = d.name
		var c := Palette.domain_color(d.id)
		var row := UI.hbox(10)
		row.add_child(UI.icon(Palette.domain_icon(d.id), 18, c))
		var name := UI.label(d.name, "MutedLabel")
		name.custom_minimum_size = Vector2(270, 0)
		row.add_child(name)
		var bar := UI.progress(0.0, c, 10)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		bar.create_tween().tween_property(bar, "value", rate, 0.8).set_delay(0.3)
		var v := UI.label("%d / %d" % [int(s.correct), int(s.total)], "SmallLabel")
		v.custom_minimum_size = Vector2(60, 0)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(v)
		list.add_child(row)
	col.add_child(UI.scroll(list))
	if not weakest.is_empty() and weakest_rate < 0.75:
		col.add_child(UI.hbox(8, [UI.icon("target", 18, Palette.INFO), UI.wrap_label("Focus next: %s — try a Practice round there." % weakest, "SmallLabel")]))
	card.add_child(col)
	return card


func _celebrate(color: Color) -> void:
	await get_tree().create_timer(0.35).timeout
	if not is_inside_tree():
		return
	if result.has_pass_mark and result.passed:
		Audio.play("exam_pass")
		FX.confetti(self, Vector2(size.x / 2.0, 120), [Palette.SUCCESS, Palette.ACCENT, Palette.ACCENT_2, Palette.INFO, Palette.PINK], 120, 170.0)
	elif not result.has_pass_mark and float(result.correct) / maxf(float(result.total), 1.0) >= 0.7:
		Audio.play("streak")
		FX.confetti(self, Vector2(size.x / 2.0, 120), [color, Palette.ACCENT_2], 60, 150.0)


func _play_again() -> void:
	var next: QuizMode = mode.get_script().new()
	next.setup(QuestionBank.pool, Profile.data, null, mode.options)
	Router.go("quiz", {"mode": next})
