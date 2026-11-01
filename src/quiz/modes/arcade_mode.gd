class_name ArcadeMode
extends QuizMode
## Survival: limited lives, countdown per question, streak multiplier, rising difficulty.
## Also used for the Daily Challenge (seeded by date, 10 questions, no lives).

const BASE_POINTS := 100
const TIME_BONUS_PER_SECOND := 10
const MAX_MULTIPLIER := 5

var _lives := 3
var _max_lives := 3
var max_questions := 0          # 0 = endless
var daily := false


func _configure() -> void:
	daily = bool(options.get("daily", false))
	key = "daily" if daily else "arcade"
	title = "Daily Challenge" if daily else "Arcade Survival"
	_max_lives = int(options.get("lives", 0 if daily else 3))
	_lives = _max_lives
	max_questions = int(options.get("max_questions", 10 if daily else 0))
	if daily:
		var seed_day := day if day >= 0 else ProfileData.today()
		rng.seed = hash("tccd-daily-%d" % seed_day)


func pick_questions() -> Array[Question]:
	var list := _ramped(pool.questions)
	if max_questions > 0 and list.size() > max_questions:
		list.resize(max_questions)
	return list


## Shuffle with a gentle difficulty ramp: easy questions tend to come first.
func _ramped(source: Array[Question]) -> Array[Question]:
	var keyed := []
	for q in source:
		keyed.append([q.difficulty + rng.randf() * 1.6, q])
	keyed.sort_custom(func(a, b): return a[0] < b[0])
	var out: Array[Question] = []
	for k in keyed:
		out.append(k[1])
	return out


func is_endless() -> bool:
	return max_questions == 0


func _refill() -> void:
	var more := _ramped(pool.questions)
	var start := questions.size()
	questions.append_array(more)
	for i in range(start, questions.size()):
		orders[i] = questions[i].shuffled_order(rng)


func max_lives() -> int:
	return _max_lives


func lives() -> int:
	return _lives


func multiplier() -> int:
	return mini(1 + streak / 3, MAX_MULTIPLIER)


func question_time_limit() -> float:
	var q := current()
	var base := clampf(22.0 - floor(correct_total / 5.0), 12.0, 22.0)
	if q != null and q.has_code():
		base += 8.0
	if q != null and q.is_multi():
		base += 4.0
	return base


func _on_answer(q: Question, ok: bool, outcome: Dictionary) -> void:
	if ok:
		var points := BASE_POINTS * q.difficulty * multiplier() + int(question_time_left() * TIME_BONUS_PER_SECOND)
		score += points
		outcome.points = points
		outcome.multiplier = multiplier()
	elif _max_lives > 0:
		_lives -= 1
		if _lives <= 0:
			outcome.game_over = true
	outcome.lives = _lives


func advance() -> bool:
	if _max_lives > 0 and _lives <= 0:
		return false
	return super.advance()


func _finalize() -> void:
	if daily:
		profile.finish_daily(score, day)
