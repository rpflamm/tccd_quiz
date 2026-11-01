extends Node
## Global access to the question pool (syllabus + all questions).

const SYLLABUS_PATH := "res://data/syllabus.json"
const QUESTIONS_DIR := "res://data/questions"

var pool := QuestionPool.new()


func _ready() -> void:
	pool.load_syllabus(SYLLABUS_PATH)
	var n := pool.load_dir(QUESTIONS_DIR)
	print("[QuestionBank] %d questions loaded" % n)
	for e in pool.errors:
		push_warning("[QuestionBank] " + e)


func domains() -> Array[Dictionary]:
	return pool.domains
