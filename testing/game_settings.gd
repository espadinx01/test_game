extends Node
## Autoload 'GameSettings': remembers the audio and window settings, applies them
## when the game starts and saves them to user://settings.cfg.
##
## Audio buses: the project only has "Master", so "Music" and "SFX" are created here.
## Every sound player that does not choose a bus itself is sent to one of them
## automatically: sounds from res://music/ go to Music, everything else goes to SFX.
## So any sound you add to a mini-game later is already covered by the sliders.

const SAVE_PATH := "user://settings.cfg"
const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const WINDOW_SIZES := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]

var master_volume := 1.0   # 0.0 to 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var fullscreen := false
var window_size := Vector2i(1920, 1080)

var _save_pending := false


func _ready() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	var has_saved_file := _load()
	window_size = _closest_size(window_size)
	_apply_audio()
	if has_saved_file:
		apply_window()   # no saved file yet: leave the window exactly as the project sets it
	get_tree().node_added.connect(_on_node_added)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()


# ---------- audio ----------

func set_master_volume(v: float) -> void:
	master_volume = v
	_apply_bus(MASTER_BUS, v)
	_queue_save()


func set_music_volume(v: float) -> void:
	music_volume = v
	_apply_bus(MUSIC_BUS, v)
	_queue_save()


func set_sfx_volume(v: float) -> void:
	sfx_volume = v
	_apply_bus(SFX_BUS, v)
	_queue_save()


func _apply_audio() -> void:
	_apply_bus(MASTER_BUS, master_volume)
	_apply_bus(MUSIC_BUS, music_volume)
	_apply_bus(SFX_BUS, sfx_volume)


func _apply_bus(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, MASTER_BUS)


func _on_node_added(node: Node) -> void:
	if not (node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D):
		return
	if node.bus != MASTER_BUS:
		return   # a bus was chosen on purpose: leave it alone
	var stream: AudioStream = node.stream
	var is_music := stream != null and stream.resource_path.begins_with("res://music/")
	node.bus = MUSIC_BUS if is_music else SFX_BUS


# ---------- window ----------

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply_window()
	_queue_save()


func step_window_size(direction: int) -> void:
	var sizes := available_window_sizes()
	var i := sizes.find(window_size)
	if i == -1:
		i = 0
	window_size = sizes[wrapi(i + direction, 0, sizes.size())]
	apply_window()
	_queue_save()


## Only the sizes that fit on the player's screen.
func available_window_sizes() -> Array[Vector2i]:
	var screen := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var out: Array[Vector2i] = []
	for s: Vector2i in WINDOW_SIZES:
		if s.x <= screen.x and s.y <= screen.y:
			out.append(s)
	if out.is_empty():
		out.append(WINDOW_SIZES[0])
	return out


func apply_window() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(window_size)
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var pos := area.position + (area.size - window_size) / 2   # centre the window
	pos.y = maxi(pos.y, area.position.y)                        # keep the title bar visible
	DisplayServer.window_set_position(pos)


func _closest_size(want: Vector2i) -> Vector2i:
	var sizes := available_window_sizes()
	var best: Vector2i = sizes[0]
	for s in sizes:
		if absi(s.x - want.x) < absi(best.x - want.x):
			best = s
	return best


# ---------- saving ----------

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("window", "fullscreen", fullscreen)
	cfg.set_value("window", "width", window_size.x)
	cfg.set_value("window", "height", window_size.y)
	cfg.save(SAVE_PATH)


func _load() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	master_volume = clampf(float(cfg.get_value("audio", "master", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("audio", "music", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx", 1.0)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("window", "fullscreen", false))
	window_size = Vector2i(int(cfg.get_value("window", "width", 1920)),
			int(cfg.get_value("window", "height", 1080)))
	return true


## Saves half a second after the last change, so dragging a slider writes the file once.
func _queue_save() -> void:
	if _save_pending:
		return
	_save_pending = true
	await get_tree().create_timer(0.5).timeout
	_save_pending = false
	save()
