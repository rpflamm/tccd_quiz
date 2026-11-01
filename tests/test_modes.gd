extends GutTest
## Unit tests for the game modes (pure logic, injected RNG and day).

const DAY := 20000

var pool: QuestionPool
var profile: ProfileData


func before_each() -> void:
	pool = QuestionPool.new()
	pool.load_syllabus("res://data/syllabus.json")
	pool.load_dir("res://tests/fixtures/questions")
	profile = ProfileData.new()


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _answer(mode: QuizMode, right: bool) -> Dictionary:
	var q := mode.current()
	if right:
		return mode.submit(q.correct)
	var wrong := []
	for i in q.answers.size():
		if not q.correct.has(i):
			wrong.append(i)
			break
	return mode.submit(wrong)


# ---- Practice -----------------------------------------------------------------

func test_practice_filters_domain_and_count() -> void:
	var m := PracticeMode.new()
	m.setup(pool, profile, _rng(), {"domain": "typo3_concepts", "count": 4, "day": DAY})
	assert_eq(m.question_count(), 4)
	for q in m.questions:
		assert_eq(q.domain, "typo3_concepts")


func test_practice_instant_feedback_records_profile() -> void:
	var m := PracticeMode.new()
	m.setup(pool, profile, _rng(), {"count": 3, "day": DAY})
	var res := _answer(m, true)
	assert_true(res.correct)
	assert_true(res.reveal)
	assert_eq(profile.counter("answered"), 1)
	# Second submit on the same question is ignored.
	assert_eq(m.submit([0]), {})
	assert_true(m.advance())
	_answer(m, false)
	assert_true(m.advance())
	_answer(m, true)
	assert_false(m.advance())
	m.finish()
	var r := m.result()
	assert_eq(r.total, 3)
	assert_eq(r.correct, 2)
	assert_eq(r.wrong_ids.size(), 1)


# ---- Exam ---------------------------------------------------------------------

func test_exam_no_feedback_and_changeable_answers() -> void:
	var m := ExamMode.new()
	m.setup(pool, profile, _rng(), {"count": 10, "minutes": 15, "day": DAY})
	assert_eq(m.question_count(), 10)
	assert_false(m.instant_feedback())
	assert_eq(m.total_time_limit(), 900.0)
	_answer(m, false)
	assert_false(m.results[0])
	_answer(m, true)                       # change answer
	assert_true(m.results[0])
	assert_eq(profile.counter("answered"), 0, "exam must not record before finish")
	m.goto(5)
	assert_eq(m.index, 5)
	m.toggle_flag()
	assert_true(m.flags.has(5))
	assert_eq(m.first_unanswered(), 1)


func test_exam_pass_mark_and_finish() -> void:
	var m := ExamMode.new()
	m.setup(pool, profile, _rng(), {"count": 15, "day": DAY})
	assert_eq(m.pass_mark(), int(ceil(15 * 51.0 / 75.0)))
	for i in m.question_count():
		m.goto(i)
		_answer(m, i < 11)
	m.finish()
	var r := m.result()
	assert_eq(r.correct, 11)
	assert_true(r.passed)
	assert_eq(profile.exam_history.size(), 1)
	assert_eq(profile.counter("answered"), 15)


func test_exam_time_up() -> void:
	var m := ExamMode.new()
	m.setup(pool, profile, _rng(), {"count": 5, "minutes": 1, "day": DAY})
	assert_eq(m.tick(30.0), "")
	assert_eq(m.tick(31.0), "time_up")


func test_exam_empty_selection_clears_answer() -> void:
	var m := ExamMode.new()
	m.setup(pool, profile, _rng(), {"count": 5, "day": DAY})
	_answer(m, true)
	assert_true(m.is_answered())
	m.submit([])
	assert_false(m.is_answered())


# ---- Arcade -------------------------------------------------------------------

func test_arcade_lives_and_game_over() -> void:
	var m := ArcadeMode.new()
	m.setup(pool, profile, _rng(), {"day": DAY})
	assert_eq(m.lives(), 3)
	_answer(m, false)
	assert_true(m.advance())
	_answer(m, false)
	assert_true(m.advance())
	var res := _answer(m, false)
	assert_true(res.game_over)
	assert_eq(m.lives(), 0)
	assert_false(m.advance())


func test_arcade_streak_multiplier_and_points() -> void:
	var m := ArcadeMode.new()
	m.setup(pool, profile, _rng(), {"day": DAY})
	for i in 6:
		_answer(m, true)
		m.advance()
	assert_eq(m.streak, 6)
	assert_eq(m.multiplier(), 3)
	assert_gt(m.score, 0)
	_answer(m, false)
	assert_eq(m.streak, 0)
	assert_eq(m.multiplier(), 1)


func test_arcade_timeout_counts_as_wrong() -> void:
	var m := ArcadeMode.new()
	m.setup(pool, profile, _rng(), {"day": DAY})
	var limit := m.question_time_limit()
	assert_gt(limit, 0.0)
	assert_eq(m.tick(limit + 0.1), "question_timeout")
	var res := m.timeout()
	assert_false(res.correct)
	assert_eq(m.lives(), 2)


func test_arcade_is_endless() -> void:
	var m := ArcadeMode.new()
	m.setup(pool, profile, _rng(), {"lives": 0, "day": DAY})
	for i in pool.size() + 5:
		_answer(m, true)
		assert_true(m.advance(), "arcade should refill at %d" % i)


func test_daily_is_deterministic_per_day() -> void:
	var a := ArcadeMode.new()
	a.setup(pool, profile, _rng(1), {"daily": true, "day": DAY})
	var b := ArcadeMode.new()
	b.setup(pool, ProfileData.new(), _rng(999), {"daily": true, "day": DAY})
	assert_eq(a.question_count(), 10)
	var ids_a := a.questions.map(func(q): return q.id)
	var ids_b := b.questions.map(func(q): return q.id)
	assert_eq(ids_a, ids_b)
	assert_eq(a.lives(), 0)
	assert_eq(a.key, "daily")


func test_daily_finish_updates_streak() -> void:
	var m := ArcadeMode.new()
	m.setup(pool, profile, _rng(), {"daily": true, "day": DAY})
	m.finish()
	assert_eq(int(profile.daily.last_day), DAY)
	assert_eq(int(profile.daily.streak), 1)


# ---- Spaced repetition ---------------------------------------------------------

func test_srs_due_first_then_new() -> void:
	var due_q := pool.get_question("API-FIX-002")
	var later_q := pool.get_question("API-FIX-003")
	profile.record_answer(due_q, false, DAY - 1)      # box 1, due DAY-1 -> due
	profile.record_answer(later_q, true, DAY)         # box 2, due DAY+1 -> not due
	var m := SrsMode.new()
	m.setup(pool, profile, _rng(), {"count": 5, "day": DAY})
	assert_eq(m.questions[0].id, "API-FIX-002")
	assert_eq(m.due_count, 1)
	assert_eq(m.new_count, 4)
	for q in m.questions:
		assert_ne(q.id, "API-FIX-003")
	assert_eq(SrsMode.due_total(pool, profile, DAY), 1)


func test_srs_falls_back_to_weakest_when_nothing_due() -> void:
	for q in pool.questions:
		profile.record_answer(q, true, DAY)            # all seen, all due tomorrow
	var m := SrsMode.new()
	m.setup(pool, profile, _rng(), {"count": 5, "day": DAY})
	assert_eq(m.question_count(), 5)


func test_finish_updates_highscore_once() -> void:
	var m := ArcadeMode.new()
	m.setup(pool, profile, _rng(), {"day": DAY})
	_answer(m, true)
	m.finish()
	assert_true(m.new_highscore)
	var s := profile.highscore("arcade")
	m.finish()                                        # idempotent
	assert_eq(profile.highscore("arcade"), s)
	assert_eq(profile.counter("games_arcade"), 1)
