extends Node
## Autoload: the current run (score, food, time), saved best result and settings, scene changes and
## audio. Everything is local (user://); no network.

signal changed

const SETTINGS_PATH := "user://settings.cfg"
const TITLE_SCENE := "res://scenes/main.tscn"
const STAGE_SCENE := "res://scenes/stage_paths.tscn"
## The browser build has no app to close: Quit goes back to the website instead.
const SITE_URL := "https://gomin2013.github.io/the-last-wild-paw/#game"
const MUSIC := preload("res://assets/audio/placeholder_music_curious_paws.mp3")
const SFX := {
	"jump": preload("res://assets/audio/placeholder_jump.wav"),
	"pounce": preload("res://assets/audio/placeholder_pounce.wav"),
	"hit": preload("res://assets/audio/placeholder_hit.wav"),
	"hurt": preload("res://assets/audio/placeholder_hurt.wav"),
	"pickup": preload("res://assets/audio/placeholder_pickup.wav"),
	"defeat": preload("res://assets/audio/placeholder_defeat.wav"),
	"clear": preload("res://assets/audio/placeholder_clear.wav"),
	"game_over": preload("res://assets/audio/placeholder_game_over.wav"),
}

## Tests point this at their own file so a test run never touches the player's best result.
var save_path := "user://save.cfg"
var stage_key := "paths"
var score := 0
var food := 0
var defeated := 0
var time := 0.0
var easter_egg := false
var running := false
var best_score := 0
var best_time := 0.0
var settings := {"master": 0.8, "music": 0.6, "sfx": 0.8, "fullscreen": false}

var _music := AudioStreamPlayer.new()
var _sfx: Array[AudioStreamPlayer] = []
var _audio_started := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	_music.stream = MUSIC
	_music.bus = "Music"
	_music.finished.connect(_music.play)
	add_child(_music)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx.append(p)
	_load_best()
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for key: String in settings:
			settings[key] = cfg.get_value("settings", key, settings[key])
	_apply_settings()


func _process(delta: float) -> void:
	if running and not get_tree().paused:
		time += delta


func _input(event: InputEvent) -> void:
	# Browsers block audio until the first input; desktop takes the same path.
	if _audio_started or not event.is_pressed():
		return
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		_audio_started = true
		_music.play()


func start_game(scene := STAGE_SCENE) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene)


func to_title() -> void:
	running = false
	stage_key = "paths"  # the title shows Stage 1's best
	_load_best()
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


func restart_stage() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_game() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = %s" % JSON.stringify(SITE_URL))
	else:
		get_tree().quit()


func start_stage(key := "paths") -> void:
	stage_key = key
	_load_best()
	score = 0
	food = 0
	defeated = 0
	time = 0.0
	easter_egg = false
	running = true
	changed.emit()


func add_food(points: int) -> void:
	food += 1
	score += points
	play_sfx("pickup")
	changed.emit()


func add_defeat(points: int) -> void:
	defeated += 1
	score += points
	play_sfx("defeat")
	changed.emit()


func add_bonus(points: int) -> void:
	score += points
	changed.emit()


## Ends the run and returns what the result screen shows. Only a cleared run can set a new best.
func finish_stage(cleared: bool) -> Dictionary:
	running = false
	var new_best := cleared and Score.is_new_best(score, time, best_score, best_time)
	if new_best:
		best_score = score
		best_time = time
		var save := ConfigFile.new()
		save.load(save_path)
		save.set_value(_best_section(), "score", best_score)
		save.set_value(_best_section(), "time", best_time)
		save.save(save_path)
	play_sfx("clear" if cleared else "game_over")
	return {
		"cleared": cleared,
		"score": score,
		"food": food,
		"defeated": defeated,
		"time": time,
		"easter_egg": easter_egg,
		"new_best": new_best,
		"best_score": best_score,
		"best_time": best_time,
	}


## Stage 1 keeps the section it had before there were more stages.
func _best_section() -> String:
	return "best" if stage_key == "paths" else "best_" + stage_key


func _load_best() -> void:
	var save := ConfigFile.new()
	save.load(save_path)
	best_score = save.get_value(_best_section(), "score", 0)
	best_time = save.get_value(_best_section(), "time", 0.0)


func play_sfx(sound: String) -> void:
	for p in _sfx:
		if not p.playing:
			p.stream = SFX[sound]
			p.play()
			return


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	_apply_settings()
	var cfg := ConfigFile.new()
	for k: String in settings:
		cfg.set_value("settings", k, settings[k])
	cfg.save(SETTINGS_PATH)


func _apply_settings() -> void:
	for bus: String in ["Master", "Music", "SFX"]:
		var idx := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_volume_db(idx, linear_to_db(float(settings[bus.to_lower()])))
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_FULLSCREEN
			if settings["fullscreen"]
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	)


static func format_time(seconds: float) -> String:
	return "%d:%04.1f" % [int(seconds) / 60, fmod(seconds, 60.0)]
