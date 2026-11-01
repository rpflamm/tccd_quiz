class_name Achievements
extends RefCounted
## Achievement definitions and checks.
## ctx keys after a finished run: mode (String), result (Dictionary from QuizMode.result()).

const LIST: Array[Dictionary] = [
	{"id": "first_steps", "icon": "star", "title": "composer require knowledge", "desc": "Answer your first question correctly."},
	{"id": "century", "icon": "check", "title": "Century", "desc": "Answer 100 questions correctly."},
	{"id": "half_k", "icon": "check", "title": "Half a Thousand", "desc": "Answer 500 questions correctly."},
	{"id": "streak_10", "icon": "flame", "title": "On Fire", "desc": "Reach a streak of 10 in Arcade mode."},
	{"id": "streak_25", "icon": "flame", "title": "Unstoppable Cache Warmup", "desc": "Reach a streak of 25 in Arcade mode."},
	{"id": "exam_taken", "icon": "clock", "title": "Exam Day", "desc": "Finish a full exam simulation (75 questions)."},
	{"id": "exam_passed", "icon": "trophy", "title": "Exam Ready", "desc": "Pass a full exam simulation (51 of 75)."},
	{"id": "exam_90", "icon": "trophy", "title": "Distinction", "desc": "Score 90 % or more in a full exam simulation."},
	{"id": "flawless", "icon": "star", "title": "No Exceptions Thrown", "desc": "Finish a practice round of 10+ questions without a mistake."},
	{"id": "daily_3", "icon": "calendar", "title": "Scheduler Task", "desc": "Complete the daily challenge 3 days in a row."},
	{"id": "daily_7", "icon": "calendar", "title": "Cron Job", "desc": "Complete the daily challenge 7 days in a row."},
	{"id": "cache_ninja", "icon": "bolt", "title": "No-Cache Ninja", "desc": "Answer 15 TYPO3 Concepts questions correctly."},
	{"id": "api_master", "icon": "bolt", "title": "API Whisperer", "desc": "Answer 25 TYPO3 APIs questions correctly."},
	{"id": "extbase_hero", "icon": "bolt", "title": "Extbase Hero", "desc": "Answer 15 Extbase questions correctly."},
	{"id": "security_guard", "icon": "shield", "title": "htmlspecialchars()", "desc": "Answer 10 Security Concepts questions correctly."},
	{"id": "breaking_news", "icon": "bolt", "title": "Breaking Change Survivor", "desc": "Answer 10 questions about v14 breaking changes correctly."},
	{"id": "leitner_25", "icon": "book", "title": "Long-Term Cache", "desc": "Move 25 questions to Leitner box 5."},
	{"id": "arcade_5000", "icon": "trophy", "title": "High Score Hacker", "desc": "Score 5000 points in Arcade mode."},
	{"id": "rank_tca", "icon": "star", "title": "TCA Tamer", "desc": "Reach the rank 'TCA Tamer'."},
]


static func check(id: String, p: ProfileData, ctx: Dictionary) -> bool:
	match id:
		"first_steps":
			return p.counter("correct") >= 1
		"century":
			return p.counter("correct") >= 100
		"half_k":
			return p.counter("correct") >= 500
		"streak_10":
			return p.counter("best_streak") >= 10
		"streak_25":
			return p.counter("best_streak") >= 25
		"exam_taken":
			return p.exam_history.any(func(e): return int(e.get("total", 0)) >= 75)
		"exam_passed":
			return p.exam_history.any(func(e): return int(e.get("total", 0)) >= 75 and bool(e.get("passed", false)))
		"exam_90":
			return p.exam_history.any(func(e): return int(e.get("total", 0)) >= 75 and float(e.get("correct", 0)) / float(e.get("total", 1)) >= 0.9)
		"flawless":
			var r: Dictionary = ctx.get("result", {})
			return ctx.get("mode", "") == "practice" and int(r.get("total", 0)) >= 10 and int(r.get("correct", 0)) == int(r.get("total", 0))
		"daily_3":
			return int(p.daily.streak) >= 3
		"daily_7":
			return int(p.daily.streak) >= 7
		"cache_ninja":
			return p.counter("correct_typo3_concepts") >= 15
		"api_master":
			return p.counter("correct_typo3_apis") >= 25
		"extbase_hero":
			return p.counter("correct_extbase") >= 15
		"security_guard":
			return p.counter("correct_security") >= 10
		"breaking_news":
			return p.counter("correct_tag_breaking-change") >= 10
		"leitner_25":
			var n := 0
			for qid in p.stats:
				if int(p.stats[qid].box) >= ProfileData.MAX_BOX:
					n += 1
			return n >= 25
		"arcade_5000":
			return p.highscore("arcade") >= 5000
		"rank_tca":
			return p.xp >= 3600
	return false


## Evaluates all achievements and unlocks new ones. Returns the newly unlocked definitions.
static func evaluate(profile: ProfileData, ctx: Dictionary = {}) -> Array[Dictionary]:
	var unlocked: Array[Dictionary] = []
	for a in LIST:
		if profile.achievements.has(a.id):
			continue
		if check(a.id, profile, ctx) and profile.unlock(a.id):
			unlocked.append(a)
	return unlocked


static func find(id: String) -> Dictionary:
	for a in LIST:
		if a.id == id:
			return a
	return {}
