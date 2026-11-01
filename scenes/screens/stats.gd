extends Screen
## Statistics: mastery radar per domain, overall numbers, per-domain accuracy.


func build() -> void:
	var p := Profile.data
	var pool: QuestionPool = QuestionBank.pool
	root.add_child(UI.header("Statistics", on_back))

	var tiles := UI.hbox(14)
	var answered := p.counter("answered")
	var correct := p.counter("correct")
	tiles.add_child(_tile("Answered", str(answered), "check", Palette.INFO))
	tiles.add_child(_tile("Accuracy", "%d %%" % int(round(100.0 * correct / maxf(answered, 1))), "target", Palette.SUCCESS))
	tiles.add_child(_tile("XP", str(p.xp), "star", Palette.ACCENT))
	tiles.add_child(_tile("Exams passed", "%d / %d" % [p.exam_history.filter(func(e): return e.get("passed", false)).size(), p.exam_history.size()], "exam", Palette.PURPLE))
	tiles.add_child(_tile("Arcade best", str(p.highscore("arcade")), "flame", Palette.ERROR))
	root.add_child(tiles)

	var body := UI.hbox(18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var radar_card := UI.panel("CardPanel")
	var rc := UI.vbox(6)
	rc.add_child(UI.label("Mastery (orange: box ≥ 3) · Accuracy (blue)", "SmallLabel"))
	var radar := RadarChart.new()
	radar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var labels := PackedStringArray()
	var values := PackedFloat32Array()
	var acc := PackedFloat32Array()
	var colors: Array[Color] = []
	for d in pool.domains:
		labels.append(_short(d.name))
		values.append(p.mastery(pool, d.id))
		acc.append(p.accuracy(d.id))
		colors.append(Palette.domain_color(d.id))
	rc.add_child(radar)
	radar_card.add_child(rc)
	body.add_child(radar_card)
	radar.set_data(labels, values, colors, acc)

	var list_card := UI.panel("CardPanel")
	list_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lc := UI.vbox(12)
	lc.add_child(UI.label("Per domain", "SmallLabel"))
	for d in pool.domains:
		var c := Palette.domain_color(d.id)
		var ds: Dictionary = p.domain_stats.get(d.id, {"answered": 0, "correct": 0})
		var row := UI.vbox(4)
		var top := UI.hbox(8)
		top.add_child(UI.icon(Palette.domain_icon(d.id), 18, c))
		var name := UI.label(d.name, "MutedLabel")
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name)
		top.add_child(UI.label("%d / %d correct · %d %% mastered" % [int(ds.correct), int(ds.answered), int(round(p.mastery(pool, d.id) * 100))], "SmallLabel"))
		row.add_child(top)
		row.add_child(UI.progress(p.mastery(pool, d.id), c, 8))
		lc.add_child(row)
	list_card.add_child(UI.scroll(lc))
	body.add_child(list_card)
	root.add_child(body)

	var reset := UI.button("Reset all progress", "refresh", "DangerButton", _confirm_reset)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_END
	root.add_child(reset)


func _short(name: String) -> String:
	return name.replace("Software Development ", "Dev ").replace("Development ", "Dev ")


func _tile(title: String, value: String, icon_name: String, color: Color) -> PanelContainer:
	var card := UI.panel("CardPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := UI.vbox(2)
	col.add_child(UI.hbox(8, [UI.icon(icon_name, 18, color), UI.label(title, "SmallLabel")]))
	var v := UI.label(value, "HeadingLabel")
	v.add_theme_color_override("font_color", color)
	col.add_child(v)
	card.add_child(col)
	return card


var _reset_armed := false


func _confirm_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		Router.toast("Click again to confirm", "This deletes XP, stats, highscores and achievements.", "cross", Palette.ERROR)
		get_tree().create_timer(4.0).timeout.connect(func(): _reset_armed = false)
		return
	Profile.reset()
	Router.toast("Progress reset", "", "refresh", Palette.INFO)
	Router.go("stats", {}, false)
