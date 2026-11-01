class_name PracticeMode
extends QuizMode
## Learning mode: pick a domain (and optionally a skill), get instant feedback with explanation.

var domain_id := ""
var skill_id := ""
var count := 10


func _configure() -> void:
	key = "practice"
	domain_id = str(options.get("domain", ""))
	skill_id = str(options.get("skill", ""))
	count = int(options.get("count", 10))
	title = "Practice: " + (pool.domain_name(domain_id) if not domain_id.is_empty() else "All Domains")


func pick_questions() -> Array[Question]:
	var list := pool.filter(domain_id, skill_id)
	# Prefer questions the player has not mastered yet: unseen and low Leitner boxes first.
	var picked := QuestionPool.sample(list, -1, rng)
	picked.sort_custom(func(a: Question, b: Question) -> bool: return profile.box_of(a.id) < profile.box_of(b.id))
	if count > 0 and picked.size() > count:
		picked.resize(count)
	return QuestionPool.sample(picked, -1, rng)


func _on_answer(_q: Question, ok: bool, outcome: Dictionary) -> void:
	if ok:
		score += 1
		outcome.points = 1
