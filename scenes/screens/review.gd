extends Screen
## Review all (or only wrong) answers of a finished run with correct answers and explanations.

var mode: QuizMode
var only_wrong := true
var _list: VBoxContainer


func setup(p: Dictionary) -> void:
	super.setup(p)
	mode = p.mode


func build() -> void:
	var toggle := CheckButton.new()
	toggle.text = "Only mistakes"
	toggle.button_pressed = only_wrong
	toggle.toggled.connect(func(v: bool):
		only_wrong = v
		_fill())
	root.add_child(UI.header("Review answers", on_back, toggle))
	_list = UI.vbox(14)
	root.add_child(UI.scroll(_list))
	_fill()


func _fill() -> void:
	for c in _list.get_children():
		c.queue_free()
	var total: int = mode.result().total
	var shown := 0
	for i in total:
		var ok: bool = mode.results.get(i, false)
		if only_wrong and ok:
			continue
		_list.add_child(_card(i, ok))
		shown += 1
	if shown == 0:
		_list.add_child(UI.center(UI.label("No mistakes — flawless!", "HeadingLabel")))
	FX.stagger(_list, 0.03)


func _card(i: int, ok: bool) -> PanelContainer:
	var q := mode.questions[i]
	var sel: Array = mode.selections.get(i, [])
	var card := UI.panel("CardPanel")
	var color := Palette.SUCCESS if ok else Palette.ERROR
	card.add_theme_stylebox_override("panel", ThemeBuilder.box(Palette.SURFACE, 16, Color(color, 0.5), 1, 22, 16))
	var col := UI.vbox(10)
	var head := UI.hbox(10)
	head.add_child(UI.icon("check" if ok else "cross", 22, color))
	head.add_child(UI.label("#%d" % (i + 1), "SubtitleLabel"))
	head.add_child(UI.chip(QuestionBank.pool.domain_name(q.domain), Palette.domain_color(q.domain), Palette.domain_icon(q.domain)))
	var skill := UI.label(QuestionBank.pool.skill_name(q.domain, q.skill), "SmallLabel")
	skill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(skill)
	if sel.is_empty():
		head.add_child(UI.chip("not answered", Palette.FAINT))
	col.add_child(head)

	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("normal_font_size", 19)
	text.text = TextFormat.inline_code(q.text)
	col.add_child(text)
	if q.has_code():
		col.add_child(CodeView.new(q.code_src, q.code_lang))

	for a in q.answers.size():
		var is_right := q.correct.has(a)
		var picked := sel.has(a)
		if not is_right and not picked:
			continue
		var row := UI.hbox(8)
		var ic := "check" if is_right else "cross"
		var c := Palette.SUCCESS if is_right else Palette.ERROR
		row.add_child(UI.icon(ic, 18, c))
		var tag := ""
		if is_right and picked:
			tag = "your answer · correct"
		elif is_right:
			tag = "correct answer"
		else:
			tag = "your answer"
		var l := RichTextLabel.new()
		l.bbcode_enabled = true
		l.fit_content = true
		l.scroll_active = false
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("normal_font_size", 17)
		l.text = "%s  [color=#%s][font_size=13]%s[/font_size][/color]" % [TextFormat.inline_code(q.answers[a]), Palette.MUTED.to_html(false), tag]
		row.add_child(l)
		col.add_child(row)

	var expl := UI.wrap_label(q.explanation, "MutedLabel")
	col.add_child(expl)
	if not q.doc_url.is_empty():
		var doc := UI.button("Read the docs", "external", "GhostButton", func(): OS.shell_open(q.doc_url))
		doc.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		col.add_child(doc)
	card.add_child(col)
	return card


func on_back() -> void:
	Router.go("results", {"mode": mode, "old_xp": Profile.data.xp, "revisit": true})
