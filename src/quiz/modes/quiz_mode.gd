class_name QuizMode
extends RefCounted
## Base class for all game modes. The quiz screen drives a mode via:
## setup() -> loop { current(), tick(delta), submit()/timeout(), advance() } -> finish() -> result()
## Modes are pure logic (no nodes), so they can be unit-tested with injected RNG, day and time.

var key := "base"
var title := "Quiz"
var pool: QuestionPool
var profile: ProfileData
var rng: RandomNumberGenerator
var options := {}
var scoring := "all_or_nothing"
var day := -1                       # -1 = today (inject in tests)

var questions: Array[Question] = []
var index := 0
var selections := {}                # question index -> Array of selected original answer indices
var results := {}                   # question index -> bool
var orders := {}                    # question index -> Array[int] display order
var flags := {}                     # question index -> true (exam: marked for review)
var score := 0
var correct_total := 0
var streak := 0
var best_streak := 0
var xp_gained := 0
var elapsed := 0.0                  # total seconds played
var question_elapsed := 0.0         # seconds on the current question
var finished := false
var new_highscore := false
var unlocked: Array[Dictionary] = []


func setup(p_pool: QuestionPool, p_profile: ProfileData, p_rng: RandomNumberGenerator = null, p_options: Dictionary = {}) -> void:
	pool = p_pool
	profile = p_profile
	rng = p_rng if p_rng != null else RandomNumberGenerator.new()
	if p_rng == null:
		rng.randomize()
	options = p_options
	scoring = str(options.get("scoring", "all_or_nothing"))
	if options.has("day"):
		day = int(options.day)
	_configure()
	questions = pick_questions()
	for i in questions.size():
		orders[i] = questions[i].shuffled_order(rng)


# ---- capabilities (override) -------------------------------------------------

func _configure() -> void:
	pass


func pick_questions() -> Array[Question]:
	return []


## Show correct answer + explanation directly after each answer.
func instant_feedback() -> bool:
	return true


## Free navigation between questions (exam).
func allows_navigation() -> bool:
	return false


## Seconds for the current question, 0 = unlimited.
func question_time_limit() -> float:
	return 0.0


## Seconds for the whole run, 0 = unlimited.
func total_time_limit() -> float:
	return 0.0


func max_lives() -> int:
	return 0


func lives() -> int:
	return 0


func is_endless() -> bool:
	return false


# ---- flow ---------------------------------------------------------------------

func current() -> Question:
	if index < 0 or index >= questions.size():
		return null
	return questions[index]


func question_count() -> int:
	return questions.size()


func display_order(i: int = -1) -> Array:
	return orders.get(index if i < 0 else i, [])


func answered_count() -> int:
	return selections.size()


func is_answered(i: int = -1) -> bool:
	return selections.has(index if i < 0 else i)


func time_left() -> float:
	var limit := total_time_limit()
	return maxf(limit - elapsed, 0.0) if limit > 0.0 else 0.0


func question_time_left() -> float:
	var limit := question_time_limit()
	return maxf(limit - question_elapsed, 0.0) if limit > 0.0 else 0.0


## Advance timers. Returns "", "question_timeout" or "time_up".
func tick(delta: float) -> String:
	if finished:
		return ""
	elapsed += delta
	question_elapsed += delta
	if total_time_limit() > 0.0 and elapsed >= total_time_limit():
		return "time_up"
	if question_time_limit() > 0.0 and question_elapsed >= question_time_limit() and not is_answered():
		return "question_timeout"
	return ""


## Submit the selection (original answer indices) for the current question.
## Returns {correct, points, xp, reveal, game_over, streak}.
func submit(selected: Array) -> Dictionary:
	var q := current()
	if q == null or (is_answered() and instant_feedback()):
		return {}
	var ok := q.is_correct(selected)
	selections[index] = selected.duplicate()
	results[index] = ok
	var outcome := {"correct": ok, "points": 0, "xp": 0, "reveal": instant_feedback(), "game_over": false, "streak": 0}
	if instant_feedback():
		outcome.xp = profile.record_answer(q, ok, day)
		xp_gained += outcome.xp
		if ok:
			correct_total += 1
			streak += 1
			best_streak = maxi(best_streak, streak)
		else:
			streak = 0
	outcome.streak = streak
	_on_answer(q, ok, outcome)
	return outcome


## Current question ran out of time: counts as a wrong answer.
func timeout() -> Dictionary:
	var outcome := submit([])
	outcome["timeout"] = true
	return outcome


func _on_answer(_q: Question, _ok: bool, _outcome: Dictionary) -> void:
	pass


## Go to next question. Returns false when the run is over.
func advance() -> bool:
	question_elapsed = 0.0
	index += 1
	if index >= questions.size():
		if is_endless() and not finished:
			_refill()
		if index >= questions.size():
			return false
	return not finished


func goto(i: int) -> void:
	if allows_navigation() and i >= 0 and i < questions.size():
		index = i


func toggle_flag(i: int = -1) -> void:
	var at := index if i < 0 else i
	if flags.has(at):
		flags.erase(at)
	else:
		flags[at] = true


func _refill() -> void:
	pass


## Finalise the run: score, highscore, achievements. Safe to call once.
func finish() -> void:
	if finished:
		return
	finished = true
	_finalize()
	profile.set_max_counter("best_streak", best_streak)
	profile.add_counter("games_" + key)
	new_highscore = profile.submit_highscore(key, score)
	unlocked = Achievements.evaluate(profile, {"mode": key, "result": result()})


func _finalize() -> void:
	pass


func passed() -> bool:
	return false


func has_pass_mark() -> bool:
	return false


func result() -> Dictionary:
	var per_domain := {}
	var wrong: Array[String] = []
	var answered := 0
	var total := questions.size() if not is_endless() else selections.size()
	for i in total:
		var q := questions[i]
		var d: Dictionary = per_domain.get(q.domain, {"total": 0, "correct": 0})
		d.total += 1
		if results.get(i, false):
			d.correct += 1
		else:
			wrong.append(q.id)
		if selections.has(i):
			answered += 1
		per_domain[q.domain] = d
	var correct := 0
	for i in results:
		if i < total and results[i]:
			correct += 1
	return {
		"mode": key,
		"title": title,
		"total": total,
		"answered": answered,
		"correct": correct,
		"score": score,
		"best_streak": best_streak,
		"xp": xp_gained,
		"seconds": int(elapsed),
		"per_domain": per_domain,
		"wrong_ids": wrong,
		"passed": passed(),
		"has_pass_mark": has_pass_mark(),
		"new_highscore": new_highscore,
	}
