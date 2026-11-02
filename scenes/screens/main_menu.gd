extends Screen
## Main menu: profile card, mode cards, navigation. Single column on phones in portrait.

var _cards: GridContainer


func build() -> void:
	Audio.play_music("menu")
	var p := Profile.data
	var pool: QuestionPool = QuestionBank.pool

	# ---- top row: logo + profile
	var brand := UI.hbox(pick(24, 16, 12))
	var logo := TextureRect.new()
	logo.texture = load("res://assets/icons/app_icon.svg")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var logo_size: int = pick(84, 60, 52)
	logo.custom_minimum_size = Vector2(logo_size, logo_size)
	brand.add_child(logo)
	var title_col := UI.vbox(0)
	title_col.add_child(UI.label("TCCD Quizz", "TitleLabel"))
	var sub_text := "Get ready for the TYPO3 CMS Certified Developer exam  ·  v14 LTS"
	if portrait():
		sub_text = "TYPO3 CMS Certified Developer · v14 LTS"
	var sub := UI.wrap_label(sub_text, "MutedLabel")
	title_col.add_child(sub)
	title_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_child(title_col)

	var content := UI.vbox(pick(18, 12, 12))
	if portrait():
		content.add_child(brand)
		content.add_child(_profile_card(p))
	else:
		var top := UI.hbox(24)
		brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(brand)
		top.add_child(_profile_card(p))
		content.add_child(top)
	if WebUpdate.available:
		content.add_child(_update_banner())

	# ---- mode cards
	_cards = GridContainer.new()
	_cards.columns = pick(3, 3, 1)
	var gap: int = pick(18, 12, 10)
	_cards.add_theme_constant_override("h_separation", gap)
	_cards.add_theme_constant_override("v_separation", gap)
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var due := SrsMode.due_total(pool, p)
	var last_exam := "No exam taken yet"
	if not p.exam_history.is_empty():
		var e: Dictionary = p.exam_history.back()
		last_exam = "Last: %d / %d  %s" % [int(e.correct), int(e.total), "PASSED" if e.passed else "failed"]
	var daily_text := "Done today ✓  ·  streak %d" % int(p.daily.streak) if p.daily_done() else "10 questions · same for everyone today"
	_add_card("Exam Simulation", "75 questions · 90 minutes · pass with 51 — just like the real thing.", "exam", Palette.ACCENT, last_exam, func(): Router.go("exam_setup"))
	_add_card("Practice", "Train a single domain with instant feedback, explanations and doc links.", "target", Palette.INFO, "%d questions in %d domains" % [pool.size(), pool.domains.size()], func(): Router.go("practice_setup"))
	_add_card("Arcade Survival", "3 lives, a ticking clock and a streak multiplier. How far can you go?", "flame", Palette.ERROR, "Highscore: %d" % p.highscore("arcade"), _start_arcade)
	_add_card("Spaced Repetition", "Leitner boxes bring back exactly the questions you are about to forget.", "brain", Palette.PURPLE, "%d due today" % due if due > 0 else "Nothing due — learn new questions", func(): Router.go("srs_setup"))
	_add_card("Daily Challenge", "A fresh seeded set every day. Keep your streak alive!", "calendar", Palette.WARNING, daily_text, _start_daily)
	_add_card("Statistics", "Mastery radar, accuracy per domain and your exam history.", "chart", Palette.TEAL, "Rank: " + Ranks.title_for(p.xp), func(): Router.go("stats"))
	content.add_child(_cards)

	# ---- bottom bar
	var buttons := UI.hbox(10)
	var ach_text := "%d / %d" if portrait() else "Achievements  %d / %d"
	buttons.add_child(UI.button(ach_text % [p.achievements.size(), Achievements.LIST.size()], "trophy", "", func(): Router.go("achievements")))
	buttons.add_child(UI.button("Settings", "gear", "", func(): Router.go("settings")))
	if OS.get_name() != "Web" and not Layout.touch:
		buttons.add_child(UI.button("Quit", "cross", "GhostButton", func(): get_tree().quit()))
	var note := UI.wrap_label("Unofficial practice tool · not affiliated with the TYPO3 Association or TYPO3 GmbH", "SmallLabel")
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if portrait():
		for b in buttons.get_children():
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(buttons)
		content.add_child(note)
		root.add_child(UI.scroll(content))
	else:
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		buttons.add_child(note)
		var bottom := buttons
		if compact():
			root.add_child(UI.scroll(content))
		else:
			content.size_flags_vertical = Control.SIZE_EXPAND_FILL
			root.add_child(content)
		root.add_child(bottom)

	if not params.get("reloaded", false):
		FX.stagger(_cards, 0.06)
	if pool.size() == 0:
		Router.toast("No questions found", "data/questions/*.json is empty.", "cross", Palette.ERROR)


func _profile_card(p: ProfileData) -> PanelContainer:
	var card := UI.panel("CardPanel")
	card.custom_minimum_size = Vector2(0 if portrait() else 340, 0)
	var col := UI.vbox(6)
	var row := UI.hbox(10)
	row.add_child(UI.icon("star", 22, Palette.ACCENT_2))
	var rank := UI.label(Ranks.title_for(p.xp), "SubtitleLabel")
	rank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rank)
	row.add_child(UI.label("Lv %d" % (Ranks.level_for(p.xp) + 1), "SmallLabel"))
	col.add_child(row)
	var bar := UI.progress(0.0, Palette.ACCENT, 8)
	col.add_child(bar)
	bar.create_tween().tween_property(bar, "value", Ranks.progress(p.xp), 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var info := UI.hbox(14)
	info.add_child(UI.label("%d / %d XP" % [p.xp, Ranks.next_xp(p.xp)], "SmallLabel"))
	info.add_child(UI.spacer())
	info.add_child(UI.icon("flame", 16, Palette.WARNING if int(p.daily.streak) > 0 else Palette.FAINT))
	info.add_child(UI.label("%d day streak" % int(p.daily.streak), "SmallLabel"))
	col.add_child(info)
	card.add_child(col)
	return card


## Shown on Web when a new build is waiting in the service worker (see WebUpdate).
func _update_banner() -> PanelContainer:
	var card := UI.panel("CardPanel")
	card.add_theme_stylebox_override("panel", ThemeBuilder.box(Palette.SURFACE, 16, Color(Palette.INFO, 0.6), 1, 16, 12))
	var row := UI.hbox(12)
	row.add_child(UI.icon("refresh", 26, Palette.INFO))
	var col := UI.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.label("Update available", "SubtitleLabel"))
	col.add_child(UI.wrap_label("A new version is ready. Reload to use it — your progress is kept.", "SmallLabel"))
	row.add_child(col)
	var reload := UI.button("Reload", "refresh", "", func(): WebUpdate.apply())
	reload.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(reload)
	card.add_child(row)
	return card


func _add_card(title: String, desc: String, icon_name: String, color: Color, footer: String, on_press: Callable) -> void:
	var card := ClickCard.new(color)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if compact():
		card.add_theme_stylebox_override("panel", ThemeBuilder.box(Palette.SURFACE, 16, Palette.BORDER, 1, 16, 12))
		card._base_style = card.get_theme_stylebox("panel")
	var col := UI.vbox(pick(10, 6, 6))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := UI.hbox(14)
	head.add_child(ClickCard.icon_badge(icon_name, color, pick(52, 40, 44)))
	var t := UI.label(title, "SubtitleLabel")
	t.add_theme_font_size_override("font_size", pick(22, 19, 20))
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(t)
	col.add_child(head)
	col.add_child(UI.wrap_label(desc, "MutedLabel"))
	if not portrait():
		col.add_child(UI.spacer(false))
	var f := UI.label(footer, "SmallLabel")
	f.add_theme_color_override("font_color", color.lightened(0.2))
	col.add_child(f)
	card.add_child(col)
	card.pressed.connect(on_press)
	_cards.add_child(card)


func _start_arcade() -> void:
	var mode := ArcadeMode.new()
	mode.setup(QuestionBank.pool, Profile.data, null, {})
	Router.go("quiz", {"mode": mode})


func _start_daily() -> void:
	if Profile.data.daily_done():
		Router.toast("Already done today", "Playing again won't change your streak — have fun!", "calendar", Palette.WARNING)
	var mode := ArcadeMode.new()
	mode.setup(QuestionBank.pool, Profile.data, null, {"daily": true})
	Router.go("quiz", {"mode": mode})


func on_back() -> void:
	pass
