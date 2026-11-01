class_name Ranks
extends RefCounted
## XP based ranks. Titles are playful TYPO3 developer career steps.

const LIST := [
	{"xp": 0, "title": "Hello World"},
	{"xp": 200, "title": "Composer Requirer"},
	{"xp": 600, "title": "Extension Kickstarter"},
	{"xp": 1200, "title": "TypoScript Tinkerer"},
	{"xp": 2200, "title": "Extbase Apprentice"},
	{"xp": 3600, "title": "TCA Tamer"},
	{"xp": 5500, "title": "Event Listener"},
	{"xp": 8000, "title": "Caching Whisperer"},
	{"xp": 11500, "title": "DataHandler Diplomat"},
	{"xp": 16000, "title": "Core Contributor"},
	{"xp": 22000, "title": "Core Merger"},
	{"xp": 30000, "title": "Certified Legend"},
]


static func level_for(xp: int) -> int:
	var level := 0
	for i in LIST.size():
		if xp >= LIST[i].xp:
			level = i
	return level


static func title_for(xp: int) -> String:
	return LIST[level_for(xp)].title


## Progress 0..1 towards the next rank (1.0 at max rank).
static func progress(xp: int) -> float:
	var level := level_for(xp)
	if level >= LIST.size() - 1:
		return 1.0
	var lo: int = LIST[level].xp
	var hi: int = LIST[level + 1].xp
	return float(xp - lo) / float(hi - lo)


static func next_xp(xp: int) -> int:
	var level := level_for(xp)
	if level >= LIST.size() - 1:
		return LIST[level].xp
	return LIST[level + 1].xp
