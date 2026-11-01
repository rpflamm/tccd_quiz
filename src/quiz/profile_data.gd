class_name ProfileData
extends RefCounted
## Persistent player progress: XP, per-question stats incl. Leitner boxes, highscores, achievements.

const VERSION := 1
## Leitner boxes 1..5 -> days until the question is due again.
const LEITNER_INTERVALS := [0, 1, 3, 7, 14]
const MAX_BOX := 5
const MAX_EXAM_HISTORY := 50

var xp: int = 0
var stats := {}            # question id -> {seen, correct, box, due, last}
var domain_stats := {}     # domain id -> {answered, correct}
var highscores := {}       # mode key -> int
var achievements := {}     # achievement id -> unix time
var exam_history: Array = []  # [{time, correct, total, passed, minutes, per_domain}]
var counters := {}         # free counters: answered, correct, best_streak, games_<mode>, ...
var daily := {"last_day": -1, "streak": 0, "best_score": 0, "last_score": 0}


static func today() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


## Records an answer. Updates Leitner box and due day. Returns XP gained.
func record_answer(q: Question, was_correct: bool, day: int = -1) -> int:
	if day < 0:
		day = today()
	var s: Dictionary = stats.get(q.id, {"seen": 0, "correct": 0, "box": 1, "due": day, "last": -1})
	s.seen += 1
	s.last = day
	if was_correct:
		s.correct += 1
		s.box = mini(int(s.box) + 1, MAX_BOX)
	else:
		s.box = 1
	s.due = day + LEITNER_INTERVALS[int(s.box) - 1]
	stats[q.id] = s

	var d: Dictionary = domain_stats.get(q.domain, {"answered": 0, "correct": 0})
	d.answered += 1
	if was_correct:
		d.correct += 1
	domain_stats[q.domain] = d

	add_counter("answered")
	if was_correct:
		add_counter("correct")
		add_counter("correct_" + q.domain)
		for t in q.tags:
			add_counter("correct_tag_" + t)
		var gained := 10 * q.difficulty
		xp += gained
		return gained
	return 0


func box_of(id: String) -> int:
	return int(stats.get(id, {}).get("box", 0))


func is_due(id: String, day: int = -1) -> bool:
	if day < 0:
		day = today()
	if not stats.has(id):
		return false
	return int(stats[id].due) <= day


func is_seen(id: String) -> bool:
	return stats.has(id)


func accuracy(domain_id: String) -> float:
	var d: Dictionary = domain_stats.get(domain_id, {})
	if d.is_empty() or int(d.answered) == 0:
		return 0.0
	return float(d.correct) / float(d.answered)


## Mastery of a domain = share of its questions that reached Leitner box >= 3.
func mastery(pool: QuestionPool, domain_id: String) -> float:
	var list := pool.filter(domain_id)
	if list.is_empty():
		return 0.0
	var mastered := 0
	for q in list:
		if box_of(q.id) >= 3:
			mastered += 1
	return float(mastered) / float(list.size())


func add_counter(key: String, amount: int = 1) -> int:
	counters[key] = int(counters.get(key, 0)) + amount
	return counters[key]


func counter(key: String) -> int:
	return int(counters.get(key, 0))


func set_max_counter(key: String, value: int) -> void:
	counters[key] = maxi(counter(key), value)


## Returns true when the score is a new highscore.
func submit_highscore(key: String, score: int) -> bool:
	if score > int(highscores.get(key, 0)):
		highscores[key] = score
		return true
	return false


func highscore(key: String) -> int:
	return int(highscores.get(key, 0))


func add_exam(entry: Dictionary) -> void:
	exam_history.append(entry)
	while exam_history.size() > MAX_EXAM_HISTORY:
		exam_history.pop_front()


## Call when a daily challenge was finished. Updates the daily streak.
func finish_daily(score: int, day: int = -1) -> void:
	if day < 0:
		day = today()
	if int(daily.last_day) == day:
		daily.best_score = maxi(int(daily.best_score), score)
		daily.last_score = score
		return
	daily.streak = int(daily.streak) + 1 if int(daily.last_day) == day - 1 else 1
	daily.last_day = day
	daily.last_score = score
	daily.best_score = maxi(int(daily.best_score), score)


func daily_done(day: int = -1) -> bool:
	if day < 0:
		day = today()
	return int(daily.last_day) == day


func unlock(achievement_id: String) -> bool:
	if achievements.has(achievement_id):
		return false
	achievements[achievement_id] = int(Time.get_unix_time_from_system())
	return true


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"xp": xp,
		"stats": stats,
		"domain_stats": domain_stats,
		"highscores": highscores,
		"achievements": achievements,
		"exam_history": exam_history,
		"counters": counters,
		"daily": daily,
	}


static func from_dict(d: Dictionary) -> ProfileData:
	var p := ProfileData.new()
	p.xp = int(d.get("xp", 0))
	p.stats = d.get("stats", {})
	p.domain_stats = d.get("domain_stats", {})
	p.highscores = d.get("highscores", {})
	p.achievements = d.get("achievements", {})
	p.exam_history = d.get("exam_history", [])
	p.counters = d.get("counters", {})
	var daily_in: Dictionary = d.get("daily", {})
	for k in daily_in:
		p.daily[k] = daily_in[k]
	# JSON numbers come back as floats; normalise the ones we do integer math with.
	for id in p.stats:
		for k in ["seen", "correct", "box", "due", "last"]:
			p.stats[id][k] = int(p.stats[id].get(k, 0))
	return p
