extends Node
## Persists ProfileData to user://profile.json (IndexedDB on Web).

signal xp_changed(old_xp: int, new_xp: int)
signal achievement_unlocked(def: Dictionary)

const PATH := "user://profile.json"

var data := ProfileData.new()


func _ready() -> void:
	load_profile()
	if OS.has_feature("web"):
		# Ask the browser to keep IndexedDB data (prevents Safari's 7-day eviction for installed apps
		# and makes Chrome/Firefox treat the storage as persistent).
		JavaScriptBridge.eval("navigator.storage && navigator.storage.persist && navigator.storage.persist()", true)


func load_profile() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		data = ProfileData.from_dict(parsed)


func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("[Profile] cannot write %s" % PATH)
		return
	f.store_string(JSON.stringify(data.to_dict()))


func reset() -> void:
	data = ProfileData.new()
	save()


func notify_xp(old_xp: int) -> void:
	if old_xp != data.xp:
		xp_changed.emit(old_xp, data.xp)


func notify_unlocked(list: Array[Dictionary]) -> void:
	for a in list:
		achievement_unlocked.emit(a)
