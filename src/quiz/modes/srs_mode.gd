class_name SrsMode
extends QuizMode
## Spaced repetition (Leitner system): due questions first (lowest box first), then new ones.

var count := 20
var domain_id := ""
var due_count := 0
var new_count := 0


func _configure() -> void:
	key = "srs"
	title = "Spaced Repetition"
	count = int(options.get("count", 20))
	domain_id = str(options.get("domain", ""))


func pick_questions() -> Array[Question]:
	var today := day if day >= 0 else ProfileData.today()
	var due: Array[Question] = []
	var fresh: Array[Question] = []
	var rest: Array[Question] = []
	for q in QuestionPool.sample(pool.filter(domain_id), -1, rng):
		if not profile.is_seen(q.id):
			fresh.append(q)
		elif profile.is_due(q.id, today):
			due.append(q)
		else:
			rest.append(q)
	due.sort_custom(func(a: Question, b: Question) -> bool: return profile.box_of(a.id) < profile.box_of(b.id))
	var out: Array[Question] = []
	for q in due:
		if out.size() >= count:
			break
		out.append(q)
	due_count = out.size()
	for q in fresh:
		if out.size() >= count:
			break
		out.append(q)
	new_count = out.size() - due_count
	if out.is_empty():
		# Everything is learned and nothing is due: review the weakest questions anyway.
		rest.sort_custom(func(a: Question, b: Question) -> bool: return profile.box_of(a.id) < profile.box_of(b.id))
		for q in rest:
			if out.size() >= count:
				break
			out.append(q)
	return out


## Number of questions currently due (for the menu badge).
static func due_total(p_pool: QuestionPool, p_profile: ProfileData, today: int = -1) -> int:
	if today < 0:
		today = ProfileData.today()
	var n := 0
	for q in p_pool.questions:
		if p_profile.is_seen(q.id) and p_profile.is_due(q.id, today):
			n += 1
	return n


func _on_answer(_q: Question, ok: bool, outcome: Dictionary) -> void:
	if ok:
		score += 1
		outcome.points = 1
