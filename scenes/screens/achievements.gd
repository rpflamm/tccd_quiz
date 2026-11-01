extends Screen
## Grid of all achievements (locked / unlocked).


func build() -> void:
	var p := Profile.data
	root.add_child(UI.header(("%d / %d" if portrait() else "Achievements  %d / %d") % [p.achievements.size(), Achievements.LIST.size()], on_back))
	var grid := GridContainer.new()
	grid.columns = pick(3, 2, 1)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for a in Achievements.LIST:
		var unlocked := p.achievements.has(a.id)
		var color := Palette.WARNING if unlocked else Palette.FAINT
		var card := UI.panel("CardPanel")
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if unlocked:
			card.add_theme_stylebox_override("panel", ThemeBuilder.box(Palette.SURFACE, 18, Color(Palette.WARNING, 0.6), 1, 20, 16))
		var row := UI.hbox(14)
		row.add_child(ClickCard.icon_badge(a.icon if unlocked else "lock", color, 48))
		var col := UI.vbox(2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var t := UI.label(a.title, "SubtitleLabel")
		if not unlocked:
			t.add_theme_color_override("font_color", Palette.MUTED)
		col.add_child(t)
		col.add_child(UI.wrap_label(a.desc, "SmallLabel"))
		if unlocked:
			var date := Time.get_date_string_from_unix_time(int(p.achievements[a.id]))
			var d := UI.label("Unlocked " + date, "SmallLabel")
			d.add_theme_color_override("font_color", Palette.WARNING)
			col.add_child(d)
		row.add_child(col)
		card.add_child(row)
		grid.add_child(card)
	root.add_child(UI.scroll(grid))
	FX.stagger(grid, 0.03)
