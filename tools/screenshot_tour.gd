extends SceneTree
## Visual smoke test: starts the real game, visits every screen, plays a few answers and saves screenshots.
## Usage (windowed, needs a GPU):  godot --path . -s tools/screenshot_tour.gd -- <output_dir>
## Uses a throw-away profile so the player's progress is not touched.

var out_dir := "user://screenshots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("[tour] screenshot ", name)


func _router() -> Node:
	return root.get_node("Router")


func _go(screen: String, params: Dictionary = {}) -> void:
	_router().go(screen, params, false)
	await _wait(1.2)


func _run() -> void:
	root.get_node("Settings").reduced_motion = false
	var profile = root.get_node("Profile")
	profile.data = ProfileData.new()            # in-memory profile, never saved by the tour
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	await _wait(1.5)
	await _shot("01_main_menu")
	await _go("practice_setup")
	await _shot("02_practice_setup")
	await _go("exam_setup")
	await _shot("03_exam_setup")
	await _go("srs_setup")
	await _shot("04_srs_setup")

	var pool: QuestionPool = root.get_node("QuestionBank").pool
	# Practice round: answer first correctly, second wrong.
	var mode := PracticeMode.new()
	mode.setup(pool, profile.data, null, {"count": 3})
	await _go("quiz", {"mode": mode})
	await _shot("05_quiz_question")
	var screen = _router().current
	screen._selected = mode.current().correct.duplicate()
	screen._submit()
	await _wait(0.9)
	await _shot("06_quiz_correct")
	screen._continue()
	await _wait(0.6)
	var q := mode.current()
	var wrong := []
	for i in q.answers.size():
		if not q.correct.has(i):
			wrong = [i]
			break
	screen._selected = wrong
	screen._submit()
	await _wait(0.9)
	await _shot("07_quiz_wrong")
	screen._continue()
	await _wait(0.5)
	screen._selected = mode.current().correct.duplicate()
	screen._submit()
	await _wait(0.4)
	screen._continue()
	await _wait(2.5)
	await _shot("08_results")
	await _go("review", {"mode": mode})
	await _shot("09_review")

	# Arcade with countdown
	var arcade := ArcadeMode.new()
	arcade.setup(pool, profile.data, null, {})
	await _go("quiz", {"mode": arcade})
	await _wait(3.0)
	await _shot("10_arcade")

	# Exam overview
	var exam := ExamMode.new()
	exam.setup(pool, profile.data, null, {"count": 75})
	await _go("quiz", {"mode": exam})
	await _shot("11_exam")
	_router().current._show_overview()
	await _wait(0.5)
	await _shot("12_exam_overview")

	await _go("stats")
	await _shot("13_stats")
	await _go("achievements")
	await _shot("14_achievements")
	await _go("settings")
	await _shot("15_settings")
	print("[tour] done")
	quit()
