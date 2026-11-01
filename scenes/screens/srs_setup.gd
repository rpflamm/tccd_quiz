extends Screen
## Spaced repetition overview: Leitner box distribution, due/new counts and start.


func build() -> void:
	root.add_child(UI.header("Spaced repetition", on_back))
	root.add_child(UI.wrap_label("The Leitner system: a correct answer moves a question one box up and it returns later (box 1: today, 2: 1 day, 3: 3 days, 4: 7 days, 5: 14 days). A mistake sends it back to box 1.", "MutedLabel"))

	var pool: QuestionPool = QuestionBank.pool
	var p := Profile.data
	var boxes := [0, 0, 0, 0, 0]
	var unseen := 0
	for q in pool.questions:
		var b := p.box_of(q.id)
		if b == 0:
			unseen += 1
		else:
			boxes[b - 1] += 1
	var due := SrsMode.due_total(pool, p)

	var row := UI.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var colors := [Palette.ERROR, Palette.WARNING, Palette.INFO, Palette.PURPLE, Palette.SUCCESS]
	var max_box: int = maxi(boxes.max(), 1)
	for i in 5:
		var card := UI.panel("CardPanel")
		card.custom_minimum_size = Vector2(170, 230)
		var col := UI.vbox(8)
		col.add_child(UI.label("Box %d" % (i + 1), "SubtitleLabel", HORIZONTAL_ALIGNMENT_CENTER))
		var bar_holder := Control.new()
		bar_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bar_holder.custom_minimum_size = Vector2(0, 110)
		var bar := ColorRect.new()
		bar.color = colors[i]
		bar_holder.add_child(bar)
		col.add_child(bar_holder)
		var ratio := float(boxes[i]) / float(max_box)
		bar_holder.resized.connect(func():
			var h := bar_holder.size.y * ratio
			bar.size = Vector2(bar_holder.size.x * 0.5, 0)
			bar.position = Vector2(bar_holder.size.x * 0.25, bar_holder.size.y)
			var tw := bar.create_tween().set_parallel()
			tw.tween_property(bar, "size:y", h, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(bar, "position:y", bar_holder.size.y - h, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
		var n := UI.label(str(boxes[i]), "HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER)
		n.add_theme_color_override("font_color", colors[i])
		col.add_child(n)
		card.add_child(col)
		row.add_child(card)
	root.add_child(row)

	var info := UI.hbox(30)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_child(UI.hbox(8, [UI.icon("clock", 22, Palette.WARNING), UI.label("%d due today" % due, "SubtitleLabel")]))
	info.add_child(UI.hbox(8, [UI.icon("star", 22, Palette.INFO), UI.label("%d not seen yet" % unseen, "SubtitleLabel")]))
	root.add_child(info)
	root.add_child(UI.spacer(false))

	var start := UI.button("Start session (20 questions)", "play", "AccentButton", func():
		var mode := SrsMode.new()
		mode.setup(QuestionBank.pool, Profile.data, null, {"count": 20})
		Router.go("quiz", {"mode": mode}))
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.custom_minimum_size = Vector2(340, 56)
	root.add_child(start)
	start.grab_focus()
