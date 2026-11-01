class_name Question
extends RefCounted
## A single quiz question loaded from data/questions/*.json.

const CODE_LANGS := ["php", "yaml", "typoscript", "tsconfig", "html", "xml", "json", "sql", "bash", "js", "text"]

var id: String
var domain: String
var skill: String
var type: String = "single"
var difficulty: int = 1
var text: String
var code_lang: String = ""
var code_src: String = ""
var answers: PackedStringArray = []
var correct: Array[int] = []
var explanation: String
var doc_url: String
var since: String = ""
var tags: PackedStringArray = []
var review := false                 # fact-check could not fully verify this question
var review_note := ""


static func from_dict(d: Dictionary) -> Question:
	var q := Question.new()
	q.id = str(d.get("id", ""))
	q.domain = str(d.get("domain", ""))
	q.skill = str(d.get("skill", ""))
	q.type = str(d.get("type", "single"))
	q.difficulty = int(d.get("difficulty", 1))
	q.text = str(d.get("question", ""))
	var code: Variant = d.get("code")
	if code is Dictionary:
		q.code_lang = str(code.get("lang", "text"))
		q.code_src = str(code.get("src", ""))
	for a in d.get("answers", []):
		q.answers.append(str(a))
	for i in d.get("correct", []):
		q.correct.append(int(i))
	q.explanation = str(d.get("explanation", ""))
	q.doc_url = str(d.get("doc_url", ""))
	q.since = str(d.get("since", ""))
	for t in d.get("tags", []):
		q.tags.append(str(t))
	q.review = bool(d.get("review", false))
	q.review_note = str(d.get("review_note", ""))
	return q


## Returns a list of human readable problems; empty when valid.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("missing id")
	if domain.is_empty() or skill.is_empty():
		errors.append("%s: missing domain/skill" % id)
	if type != "single" and type != "multi":
		errors.append("%s: invalid type '%s'" % [id, type])
	if difficulty < 1 or difficulty > 3:
		errors.append("%s: difficulty out of range" % id)
	if text.strip_edges().length() < 10:
		errors.append("%s: question text too short" % id)
	if answers.size() < 4 or answers.size() > 6:
		errors.append("%s: needs 4-6 answers" % id)
	if correct.is_empty():
		errors.append("%s: no correct answer" % id)
	for i in correct:
		if i < 0 or i >= answers.size():
			errors.append("%s: correct index %d out of range" % [id, i])
	if type == "single" and correct.size() != 1:
		errors.append("%s: single choice needs exactly one correct answer" % id)
	if type == "multi" and (correct.size() < 2 or correct.size() >= answers.size()):
		errors.append("%s: multi choice needs >= 2 correct and >= 1 wrong answer" % id)
	if not code_src.is_empty() and not code_lang in CODE_LANGS:
		errors.append("%s: unknown code language '%s'" % [id, code_lang])
	if not doc_url.begins_with("https://"):
		errors.append("%s: doc_url must be https" % id)
	return errors


func is_multi() -> bool:
	return type == "multi"


func correct_count() -> int:
	return correct.size()


func has_code() -> bool:
	return not code_src.is_empty()


## All-or-nothing check: selection must equal the set of correct indices.
func is_correct(selected: Array) -> bool:
	if selected.size() != correct.size():
		return false
	for i in selected:
		if not correct.has(int(i)):
			return false
	return true


## Score between 0.0 and 1.0.
## "all_or_nothing": 1 only for the exact set.
## "partial": +1/k per correct pick, -1/k per wrong pick (k = number of correct answers), clamped at 0.
func score(selected: Array, mode: String = "all_or_nothing") -> float:
	if mode != "partial":
		return 1.0 if is_correct(selected) else 0.0
	var k := float(correct.size())
	var points := 0.0
	for i in selected:
		points += (1.0 / k) if correct.has(int(i)) else (-1.0 / k)
	return clampf(points, 0.0, 1.0)


## Returns a permutation of answer indices (display order -> original index).
func shuffled_order(rng: RandomNumberGenerator) -> Array[int]:
	var order: Array[int] = []
	for i in answers.size():
		order.append(i)
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	return order
