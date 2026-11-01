extends GutTest
## Validates the real question bank in data/questions (schema, syllabus mapping, unique ids).

func test_all_questions_are_valid() -> void:
	var pool := QuestionPool.new()
	assert_true(pool.load_syllabus("res://data/syllabus.json"))
	var loaded := pool.load_dir("res://data/questions")
	assert_eq(pool.errors.size(), 0, "\n".join(pool.errors))
	gut.p("%d questions loaded from data/questions" % loaded)


func test_syllabus_has_all_domains() -> void:
	var pool := QuestionPool.new()
	pool.load_syllabus("res://data/syllabus.json")
	var ids := pool.domains.map(func(d): return d.id)
	for id in ["typo3_concepts", "dev_standards", "typo3_apis", "dev_concepts", "extbase", "third_party", "security", "tooling"]:
		assert_has(ids, id)
	assert_eq(int(pool.exam_format.questions), 75)
