class_name QuestionPool
extends RefCounted
## Holds the syllabus and all questions. Pure logic, no scene tree access, so it is unit-testable.

var domains: Array[Dictionary] = []          # [{id, name, skills: [{id, name, description}]}]
var exam_format := {"questions": 75, "minutes": 90, "pass_correct": 51}
var questions: Array[Question] = []
var errors := PackedStringArray()

var _by_id := {}
var _skill_names := {}                      # "domain/skill" -> name
var _domain_names := {}


func load_syllabus(path: String) -> bool:
	var data: Variant = _read_json(path)
	if not data is Dictionary:
		errors.append("cannot read syllabus %s" % path)
		return false
	domains.clear()
	for d in data.get("domains", []):
		domains.append(d)
		_domain_names[d.id] = d.name
		for s in d.skills:
			_skill_names["%s/%s" % [d.id, s.id]] = s.name
	if data.has("exam_format"):
		exam_format = data.exam_format
	return true


## Loads every *.json file in the directory. Returns number of loaded questions.
func load_dir(dir_path: String) -> int:
	var files := PackedStringArray()
	for f in DirAccess.get_files_at(dir_path):
		# Exported builds may list remapped files; JSON files stay as-is.
		if f.get_extension() == "json":
			files.append(f)
	files.sort()
	var loaded := 0
	for f in files:
		loaded += load_file(dir_path.path_join(f))
	return loaded


func load_file(path: String) -> int:
	var data: Variant = _read_json(path)
	if not data is Dictionary or not data.get("questions") is Array:
		errors.append("%s: expected {\"questions\": [...]}" % path.get_file())
		return 0
	var loaded := 0
	for raw in data.questions:
		if raw is Dictionary and add_dict(raw):
			loaded += 1
	return loaded


func add_dict(raw: Dictionary) -> bool:
	var q := Question.from_dict(raw)
	var problems := q.validate()
	if not domains.is_empty() and not _skill_names.has("%s/%s" % [q.domain, q.skill]):
		problems.append("%s: unknown skill %s/%s" % [q.id, q.domain, q.skill])
	if _by_id.has(q.id):
		problems.append("%s: duplicate id" % q.id)
	if not problems.is_empty():
		errors.append_array(problems)
		return false
	questions.append(q)
	_by_id[q.id] = q
	return true


func size() -> int:
	return questions.size()


func get_question(id: String) -> Question:
	return _by_id.get(id)


func has_question(id: String) -> bool:
	return _by_id.has(id)


func domain_name(domain_id: String) -> String:
	return _domain_names.get(domain_id, domain_id)


func skill_name(domain_id: String, skill_id: String) -> String:
	return _skill_names.get("%s/%s" % [domain_id, skill_id], skill_id)


func filter(domain_id: String = "", skill_id: String = "", max_difficulty: int = 3) -> Array[Question]:
	var out: Array[Question] = []
	for q in questions:
		if not domain_id.is_empty() and q.domain != domain_id:
			continue
		if not skill_id.is_empty() and q.skill != skill_id:
			continue
		if q.difficulty > max_difficulty:
			continue
		out.append(q)
	return out


func count_by_domain() -> Dictionary:
	var out := {}
	for q in questions:
		out[q.domain] = out.get(q.domain, 0) + 1
	return out


## Random sample without replacement.
static func sample(list: Array[Question], count: int, rng: RandomNumberGenerator) -> Array[Question]:
	var copy: Array[Question] = list.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	if count >= 0 and count < copy.size():
		copy.resize(count)
	return copy


## Draws an exam: per-domain quotas proportional to the number of syllabus skills
## (largest remainder method), then random questions inside each domain.
func draw_exam(count: int, rng: RandomNumberGenerator) -> Array[Question]:
	var weights := {}
	var available := count_by_domain()
	var total_weight := 0
	for d in domains:
		if available.get(d.id, 0) > 0:
			weights[d.id] = d.skills.size()
			total_weight += d.skills.size()
	if total_weight == 0:
		return sample(questions, count, rng)
	var quotas := {}
	var remainders := []
	var assigned := 0
	for id in weights:
		var exact: float = float(count) * weights[id] / total_weight
		quotas[id] = mini(int(floor(exact)), available[id])
		assigned += quotas[id]
		remainders.append([exact - floor(exact), id])
	remainders.sort_custom(func(a, b): return a[0] > b[0])
	var idx := 0
	var guard := 0
	while assigned < count and guard < 10000:
		var id: String = remainders[idx % remainders.size()][1]
		if quotas[id] < available[id]:
			quotas[id] += 1
			assigned += 1
		idx += 1
		guard += 1
		if assigned >= size():
			break
	var out: Array[Question] = []
	for id in quotas:
		out.append_array(sample(filter(id), quotas[id], rng))
	return sample(out, -1, rng)


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	return JSON.parse_string(text)
