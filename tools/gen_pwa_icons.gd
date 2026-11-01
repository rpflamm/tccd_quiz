extends SceneTree
## Renders the app icon SVG into the PNG sizes required by the Web export's PWA manifest.
## Usage: godot --headless --path . -s tools/gen_pwa_icons.gd

const SRC := "res://assets/icons/app_icon.svg"
const OUT_DIR := "res://assets/pwa"
const SIZES := [144, 180, 512]


func _initialize() -> void:
	var svg := FileAccess.get_file_as_string(SRC)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for size in SIZES:
		var img := Image.new()
		# The SVG is 256 px; render at the target scale for crisp edges.
		var err := img.load_svg_from_string(svg, float(size) / 256.0)
		if err != OK:
			push_error("SVG render failed: %d" % err)
			quit(1)
			return
		var path := "%s/icon_%d.png" % [OUT_DIR, size]
		img.save_png(ProjectSettings.globalize_path(path))
		print("written ", path, " ", img.get_size())
	quit()
