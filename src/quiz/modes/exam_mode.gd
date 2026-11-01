class_name ExamMode
extends QuizMode
## Exam simulation: like the real TCCD exam (75 questions, 90 minutes, pass with 51 correct).
## No feedback during the exam, free navigation, questions can be flagged for review.

var count := 75
var minutes := 90.0
var pass_ratio := 51.0 / 75.0


func _configure() -> void:
	key = "exam"
	title = "Exam Simulation"
	count = int(options.get("count", pool.exam_format.get("questions", 75)))
	minutes = float(options.get("minutes", pool.exam_format.get("minutes", 90)))
	pass_ratio = float(pool.exam_format.get("pass_correct", 51)) / float(pool.exam_format.get("questions", 75))


func pick_questions() -> Array[Question]:
	return pool.draw_exam(count, rng)


func instant_feedback() -> bool:
	return false


func allows_navigation() -> bool:
	return true


func total_time_limit() -> float:
	return minutes * 60.0


## Correct answers needed to pass for this exam length.
func pass_mark() -> int:
	return int(ceil(questions.size() * pass_ratio))


func has_pass_mark() -> bool:
	return true


func passed() -> bool:
	return correct_total >= pass_mark()


## Exams may change answers until the end: overwrite previous selection; empty selection clears it.
func submit(selected: Array) -> Dictionary:
	var q := current()
	if q == null or finished:
		return {}
	if selected.is_empty():
		selections.erase(index)
		results.erase(index)
		return {"correct": false, "reveal": false}
	selections[index] = selected.duplicate()
	results[index] = q.is_correct(selected)
	return {"correct": results[index], "reveal": false, "points": 0, "xp": 0, "game_over": false, "streak": 0}


func first_unanswered() -> int:
	for i in questions.size():
		if not selections.has(i):
			return i
	return -1


func _finalize() -> void:
	correct_total = 0
	var points := 0.0
	for i in questions.size():
		var q := questions[i]
		var ok: bool = results.get(i, false)
		if selections.has(i):
			xp_gained += profile.record_answer(q, ok, day)
			points += q.score(selections[i], scoring)
		if ok:
			correct_total += 1
	score = int(round(points * 100.0 / maxf(questions.size(), 1)))   # percent
	profile.add_exam({
		"time": int(Time.get_unix_time_from_system()),
		"correct": correct_total,
		"total": questions.size(),
		"passed": passed(),
		"seconds": int(elapsed),
		"per_domain": result().per_domain,
	})
