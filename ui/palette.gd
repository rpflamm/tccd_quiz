class_name Palette
extends RefCounted
## Central colour palette (dark theme, TYPO3-like orange accent).

const BG := Color("10121a")
const BG_2 := Color("151925")
const SURFACE := Color("1b2030")
const SURFACE_2 := Color("232a3d")
const SURFACE_3 := Color("2c344b")
const BORDER := Color("343d57")
const TEXT := Color("eceef4")
const MUTED := Color("9aa3b8")
const FAINT := Color("5d6680")
const ACCENT := Color("ff8700")
const ACCENT_2 := Color("ffb347")
const ACCENT_DARK := Color("c45f00")
const SUCCESS := Color("2fd07b")
const ERROR := Color("ff4d5e")
const WARNING := Color("ffc93c")
const INFO := Color("4da3ff")
const PURPLE := Color("a77cff")
const PINK := Color("ff6fb1")
const TEAL := Color("2ed3c6")

## One colour per syllabus domain (stable order).
const DOMAIN := {
	"typo3_concepts": Color("ff8700"),
	"typo3_apis": Color("4da3ff"),
	"dev_concepts": Color("a77cff"),
	"dev_standards": Color("2ed3c6"),
	"extbase": Color("ff6fb1"),
	"third_party": Color("ffc93c"),
	"security": Color("ff4d5e"),
	"tooling": Color("2fd07b"),
}

const DOMAIN_ICON := {
	"typo3_concepts": "bolt",
	"typo3_apis": "code",
	"dev_concepts": "brain",
	"dev_standards": "book",
	"extbase": "grid",
	"third_party": "external",
	"security": "shield",
	"tooling": "gear",
}


static func domain_color(id: String) -> Color:
	return DOMAIN.get(id, ACCENT)


static func domain_icon(id: String) -> String:
	return DOMAIN_ICON.get(id, "star")
