extends SceneTree
## Takes store screenshots from the real demo scene (no mock-ups).
## Needs a real renderer, so do not pass --headless.
##
## Run from the project folder:
##   godot --path . -s res://tools/capture_screenshots.gd
## Output: tools/out/*.png at the window size (1280x720 by default).

const OUT_DIR := "res://tools/out"
## Seconds into the demo, and a name for each shot.
const SHOTS := [
	{"at": 0.6, "name": "01-all-effects", "pixelate": false},
	{"at": 2.2, "name": "02-dissolve-and-palette", "pixelate": false},
	{"at": 2.4, "name": "03-pixelate-screen", "pixelate": true},
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var demo: Control = load("res://demo/demo.tscn").instantiate()
	root.add_child(demo)
	var start := Time.get_ticks_msec()
	for shot: Dictionary in SHOTS:
		while (Time.get_ticks_msec() - start) / 1000.0 < shot.at:
			await process_frame
		demo.screen_toggle.button_pressed = shot.pixelate
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var path := "%s/%s.png" % [OUT_DIR, shot.name]
		var err := img.save_png(ProjectSettings.globalize_path(path))
		print("shot ", path, " ", img.get_size(), " err=", err)
	quit(0)
