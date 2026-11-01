extends Screen
## Choose a domain (or all) and the round length for Practice mode.

const COUNTS := [10, 20, 40, 0]
var _count := 10
var _count_buttons: Array[Button] = []


func build() -> void:
	_count = Settings.practice_count
	var counts := UI.hbox(8)
	counts.add_child(UI.label("Questions:", "MutedLabel"))
	for c in COUNTS:
		var b := UI.button("All" if c == 0 else str(c), "", "", _set_count.bind(c))
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(64, 0)
		_count_buttons.append(b)
		counts.add_child(b)
	_refresh_counts()
	root.add_child(UI.header("Practice by domain", on_back, counts))
	root.add_child(UI.label("Pick a syllabus domain. Each answer shows an explanation and a link to the official TYPO3 documentation.", "MutedLabel"))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	var pool: QuestionPool = QuestionBank.pool
	var counts_by_domain := pool.count_by_domain()
	grid.add_child(_domain_card("", "All domains", "Mixed questions from the whole syllabus.", pool.size(), Palette.ACCENT, "star"))
	for d in pool.domains:
		var n: int = counts_by_domain.get(d.id, 0)
		grid.add_child(_domain_card(d.id, d.name, "%d skills in the syllabus" % d.skills.size(), n, Palette.domain_color(d.id), Palette.domain_icon(d.id)))
	root.add_child(UI.scroll(grid))
	FX.stagger(grid, 0.04)


func _domain_card(id: String, title: String, desc: String, n: int, color: Color, icon_name: String) -> ClickCard:
	var card := ClickCard.new(color)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := UI.vbox(8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := UI.hbox(12)
	head.add_child(ClickCard.icon_badge(icon_name, color, 44))
	var t := UI.wrap_label(title, "SubtitleLabel")
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(t)
	col.add_child(head)
	col.add_child(UI.label(desc, "SmallLabel"))
	var mastery := 0.0
	if id.is_empty():
		var total := 0.0
		for d in QuestionBank.pool.domains:
			total += Profile.data.mastery(QuestionBank.pool, d.id) * QuestionBank.pool.filter(d.id).size()
		mastery = total / maxf(QuestionBank.pool.size(), 1)
	else:
		mastery = Profile.data.mastery(QuestionBank.pool, id)
	var row := UI.hbox(8)
	row.add_child(UI.label("%d questions" % n, "SmallLabel"))
	row.add_child(UI.spacer())
	row.add_child(UI.label("mastered %d %%" % int(round(mastery * 100)), "SmallLabel"))
	col.add_child(row)
	col.add_child(UI.progress(mastery, color, 6))
	card.add_child(col)
	card.set_enabled(n > 0)
	card.pressed.connect(_start.bind(id))
	return card


func _set_count(c: int) -> void:
	_count = c
	Settings.practice_count = c
	Settings.save()
	_refresh_counts()


func _refresh_counts() -> void:
	for i in COUNTS.size():
		_count_buttons[i].set_pressed_no_signal(COUNTS[i] == _count)
		_count_buttons[i].theme_type_variation = "AccentButton" if COUNTS[i] == _count else ""


func _start(domain_id: String) -> void:
	var mode := PracticeMode.new()
	mode.setup(QuestionBank.pool, Profile.data, null, {"domain": domain_id, "count": _count})
	Router.go("quiz", {"mode": mode})
