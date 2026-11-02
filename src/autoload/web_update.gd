extends Node
## Web/PWA only: notices when the service worker has downloaded a new build and switches to it on request.
## Godot's service worker serves everything cache-first, so without this an installed app or open tab keeps
## running the old version until every tab is closed. The main menu shows a banner while `available` is set.

signal update_available

var available := false


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.pwa_update_available.connect(_on_update_available)
	# An update found during an earlier visit is already waiting and may have been reported before we connected.
	if JavaScriptBridge.pwa_needs_update():
		_on_update_available()


## Saves progress, activates the waiting service worker and reloads the page with the new build.
func apply() -> void:
	Profile.save()
	Settings.save()
	JavaScriptBridge.force_fs_sync()
	# Give the IndexedDB sync a moment before the page goes away.
	await get_tree().create_timer(0.5).timeout
	if JavaScriptBridge.pwa_update() != OK:
		JavaScriptBridge.eval("location.reload()", true)


func _on_update_available() -> void:
	if available:
		return
	available = true
	update_available.emit()
	if Router.current_name == "main_menu":
		Router.reload()
