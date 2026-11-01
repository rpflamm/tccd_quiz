extends GutTest
## Unit tests for Question, QuestionPool, ProfileData, Ranks, Achievements.

const SYLLABUS := "res://data/syllabus.json"
const FIXTURES := "res://tests/fixtures/questions"

var pool: QuestionPool


func before_each() -> void:
	pool = QuestionPool.new()
	pool.load_syllabus(SYLLABUS)
	pool.load_dir(FIXTURES)


func _rng(seed_value: int = 42) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


# ---- Question -----------------------------------------------------------------

func test_single_choice_scoring() -> void:
	var q := pool.get_question("CON-FIX-001")
	assert_true(q.is_correct([0]))
	assert_false(q.is_correct([1]))
	assert_false(q.is_correct([0, 1]))
	assert_false(q.is_correct([]))


func test_multi_choice_all_or_nothing_and_partial() -> void:
	var q := pool.get_question("CON-FIX-003")
	assert_true(q.is_multi())
	assert_eq(q.correct_count(), 2)
	assert_true(q.is_correct([3, 1]))
	assert_false(q.is_correct([1]))
	assert_eq(q.score([1], "all_or_nothing"), 0.0)
	assert_almost_eq(q.score([1], "partial"), 0.5, 0.001)
	assert_almost_eq(q.score([1, 0], "partial"), 0.0, 0.001)
	assert_almost_eq(q.score([1, 3], "partial"), 1.0, 0.001)


func test_shuffled_order_is_permutation() -> void:
	var q := pool.get_question("API-FIX-001")
	var order := q.shuffled_order(_rng())
	var sorted := order.duplicate()
	sorted.sort()
	assert_eq(sorted, [0, 1, 2, 3, 4])


func test_invalid_question_is_rejected() -> void:
	var before := pool.size()
	var ok := pool.add_dict({"id": "BAD-X-001", "domain": "extbase", "skill": "nope", "type": "single",
		"difficulty": 1, "question": "Too few answers here?", "answers": ["a", "b"], "correct": [0],
		"explanation": "x", "doc_url": "http://insecure"})
	assert_false(ok)
	assert_eq(pool.size(), before)
	assert_gt(pool.errors.size(), 0)


func test_duplicate_id_is_rejected() -> void:
	var raw := {"id": "CON-FIX-001", "domain": "extbase", "skill": pool.domains[4].skills[0].id, "type": "single",
		"difficulty": 1, "question": "Duplicate id question?", "answers": ["a", "b", "c", "d"], "correct": [0],
		"explanation": "duplicate", "doc_url": "https://docs.typo3.org/"}
	assert_false(pool.add_dict(raw))


# ---- QuestionPool ---------------------------------------------------------------

func test_pool_loads_syllabus_and_fixtures() -> void:
	assert_eq(pool.domains.size(), 8)
	assert_eq(pool.size(), 16)
	assert_eq(pool.errors.size(), 0, str(pool.errors))
	assert_eq(pool.domain_name("extbase"), "Extbase")


func test_filter_by_domain_and_difficulty() -> void:
	assert_eq(pool.filter("typo3_concepts").size(), 6)
	assert_eq(pool.filter("typo3_concepts", "", 1).size(), 2)


func test_draw_exam_respects_count_and_uniqueness() -> void:
	var drawn := pool.draw_exam(10, _rng())
	assert_eq(drawn.size(), 10)
	var ids := {}
	for q in drawn:
		ids[q.id] = true
	assert_eq(ids.size(), 10)


func test_draw_exam_caps_at_pool_size() -> void:
	assert_eq(pool.draw_exam(75, _rng()).size(), 16)


func test_draw_exam_weights_domains_by_skills() -> void:
	# typo3_apis (51 skills) must get more questions than security (3 skills).
	var drawn := pool.draw_exam(8, _rng(7))
	var by_domain := {}
	for q in drawn:
		by_domain[q.domain] = by_domain.get(q.domain, 0) + 1
	assert_gt(by_domain.get("typo3_apis", 0), by_domain.get("security", 0))


# ---- ProfileData / Leitner ------------------------------------------------------

func test_leitner_box_progression() -> void:
	var p := ProfileData.new()
	var q := pool.get_question("CON-FIX-002")
	p.record_answer(q, true, 100)
	assert_eq(p.box_of(q.id), 2)
	assert_eq(int(p.stats[q.id].due), 101)
	p.record_answer(q, true, 101)
	assert_eq(p.box_of(q.id), 3)
	assert_eq(int(p.stats[q.id].due), 104)
	p.record_answer(q, false, 104)
	assert_eq(p.box_of(q.id), 1)
	assert_true(p.is_due(q.id, 104))


func test_leitner_box_caps_at_five() -> void:
	var p := ProfileData.new()
	var q := pool.get_question("CON-FIX-002")
	for d in 10:
		p.record_answer(q, true, d)
	assert_eq(p.box_of(q.id), ProfileData.MAX_BOX)


func test_xp_and_counters() -> void:
	var p := ProfileData.new()
	var q := pool.get_question("CON-FIX-003")   # difficulty 3
	assert_eq(p.record_answer(q, true, 1), 30)
	assert_eq(p.record_answer(q, false, 1), 0)
	assert_eq(p.xp, 30)
	assert_eq(p.counter("answered"), 2)
	assert_eq(p.counter("correct"), 1)
	assert_eq(p.counter("correct_typo3_concepts"), 1)


func test_profile_roundtrip_through_json() -> void:
	var p := ProfileData.new()
	p.record_answer(pool.get_question("API-FIX-001"), true, 5)
	p.submit_highscore("arcade", 1234)
	p.finish_daily(500, 5)
	var restored := ProfileData.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	assert_eq(restored.xp, p.xp)
	assert_eq(restored.box_of("API-FIX-001"), 2)
	assert_eq(restored.highscore("arcade"), 1234)
	assert_eq(int(restored.daily.streak), 1)


func test_daily_streak() -> void:
	var p := ProfileData.new()
	p.finish_daily(100, 10)
	p.finish_daily(200, 11)
	assert_eq(int(p.daily.streak), 2)
	p.finish_daily(50, 11)            # same day again: streak unchanged
	assert_eq(int(p.daily.streak), 2)
	p.finish_daily(10, 14)            # gap: streak restarts
	assert_eq(int(p.daily.streak), 1)
	assert_eq(int(p.daily.best_score), 200)


# ---- Ranks / Achievements -------------------------------------------------------

func test_ranks() -> void:
	assert_eq(Ranks.title_for(0), "Hello World")
	assert_eq(Ranks.level_for(Ranks.LIST[3].xp), 3)
	assert_almost_eq(Ranks.progress(100), 0.5, 0.001)
	assert_eq(Ranks.progress(999999), 1.0)


func test_achievement_unlocks_once() -> void:
	var p := ProfileData.new()
	p.record_answer(pool.get_question("CON-FIX-001"), true, 1)
	var first := Achievements.evaluate(p)
	assert_true(first.any(func(a): return a.id == "first_steps"))
	var second := Achievements.evaluate(p)
	assert_false(second.any(func(a): return a.id == "first_steps"))


func test_all_achievements_have_checks() -> void:
	# Every listed achievement must be handled in Achievements.check (no silent 'false' forever).
	var p := ProfileData.new()
	p.xp = 999999
	for c in ["correct", "best_streak", "correct_typo3_concepts", "correct_typo3_apis", "correct_extbase",
			"correct_security", "correct_tag_breaking-change"]:
		p.counters[c] = 9999
	p.daily.streak = 10
	p.highscores["arcade"] = 99999
	p.exam_history.append({"total": 75, "correct": 75, "passed": true})
	for i in 30:
		p.stats["Q%d" % i] = {"box": 5}
	var ctx := {"mode": "practice", "result": {"total": 10, "correct": 10}}
	for a in Achievements.LIST:
		assert_true(Achievements.check(a.id, p, ctx), "achievement %s cannot be unlocked" % a.id)
