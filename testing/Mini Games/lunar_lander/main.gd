extends Node2D

enum GameState { PLAYING, LANDED, CRASHED }

const LANDER_SCENE := preload("res://Mini Games/lunar_lander/Lander_game.tscn")
const WORLD_WIDTH := 3200.0
const SAVE_PATH := "user://highscore.save"
const LOSE_SOUND_PATH := "res://sounds/mini_game1/lose game over.wav"   # <-- change this if your file is somewhere else
const WIN_SOUND_PATH := "res://sounds/mini_game1/next level.wav"   # <-- put the exact name of your win sound here

@export var max_landing_speed_y := 55.0
@export var max_landing_speed_x := 35.0
@export var max_landing_angle_deg := 10.0

@onready var terrain: Terrain = $Terrain
@onready var hud: Hud = $HUD

var lander: Lander
var camera: Camera2D
var game_state := GameState.PLAYING
var level := 1
var score := 0
var high_score := 0
var stars: Array[Vector3] = []
var lose_player: AudioStreamPlayer
var win_player: AudioStreamPlayer


func _ready() -> void:
	high_score = _load_high_score()
	lose_player = _make_sound_player(LOSE_SOUND_PATH)
	win_player = _make_sound_player(WIN_SOUND_PATH)
	for i in 260:
		stars.append(Vector3(randf() * WORLD_WIDTH, randf_range(-400.0, 1000.0), randf_range(0.3, 0.9)))
	_start_level()


func _draw() -> void:   # starfield (drawn before child nodes, so terrain covers it)
	for s in stars:
		draw_circle(Vector2(s.x, s.y), 1.3, Color(1, 1, 1, s.z))


func _start_level() -> void:
	game_state = GameState.PLAYING
	if lose_player:
		lose_player.stop()   # cut the game over sound when restarting
	if win_player:
		win_player.stop()   # cut the win sound when the next level starts
	if is_instance_valid(lander):
		lander.queue_free()

	var defs: Array[Dictionary] = [
		{"segments": 6, "multiplier": 1},   # 240 px wide
		{"segments": 4, "multiplier": 2},   # 160 px
		{"segments": 3, "multiplier": 4},   # 120 px
	]
	if level >= 3:
		defs.remove_at(0)   # no easy pad from level 3 on
	terrain.generate(WORLD_WIDTH, minf(30.0 + level * 8.0, 90.0), defs)

	lander = LANDER_SCENE.instantiate()
	lander.position = Vector2(randf_range(300.0, WORLD_WIDTH - 300.0), 250.0)
	lander.linear_velocity = Vector2(randf_range(-70.0, 70.0), 0.0)
	lander.touched_ground.connect(_on_lander_touched_ground)
	add_child(lander)

	camera = lander.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = -400
	camera.limit_bottom = 1300

	hud.set_status(score, high_score, level)
	hud.show_message("")


func _physics_process(_delta: float) -> void:
	if game_state != GameState.PLAYING:
		return
	_update_hud()
	var p := lander.global_position
	if p.x < -100.0 or p.x > WORLD_WIDTH + 100.0 or p.y < -600.0:
		_crash("lost in space")


func _tilt_deg() -> float:
	return absf(rad_to_deg(wrapf(lander.rotation, -PI, PI)))


func _update_hud() -> void:
	var vel := lander.linear_velocity
	var feet_y := lander.global_position.y + Lander.FOOT_OFFSET
	var altitude := maxf(terrain.get_height_at(lander.global_position.x) - feet_y, 0.0)
	hud.update_stats(lander.fuel, lander.max_fuel, altitude, vel, _tilt_deg(),
			absf(vel.x) <= max_landing_speed_x,
			absf(vel.y) <= max_landing_speed_y,
			_tilt_deg() <= max_landing_angle_deg)


func _on_lander_touched_ground(impact: Vector2) -> void:
	if game_state != GameState.PLAYING:
		return

	var x := lander.global_position.x
	var pad := terrain.get_pad_at(x - Lander.FOOT_HALF_WIDTH, x + Lander.FOOT_HALF_WIDTH)

	var problems: PackedStringArray = []
	if pad.is_empty():
		problems.append("missed the landing pad")
	if absf(impact.y) > max_landing_speed_y:
		problems.append("too fast vertically")
	if absf(impact.x) > max_landing_speed_x:
		problems.append("too much sideways speed")
	if _tilt_deg() > max_landing_angle_deg:
		problems.append("not upright")

	if problems.is_empty():
		_land_success(pad)
	else:
		_crash(", ".join(problems))


func _land_success(pad: Dictionary) -> void:
	game_state = GameState.LANDED
	if win_player:
		win_player.play()
	lander.active = false   # disable controls; physics lets it settle on its legs

	var fuel_bonus := int(lander.fuel / 10.0)
	var gained: int = 100 * pad.multiplier + fuel_bonus
	score += gained
	if score > high_score:
		high_score = score
		_save_high_score()

	hud.set_status(score, high_score, level)
	hud.show_message("PERFECT LANDING!\n+%d  (pad x%d + fuel bonus %d)\nPress Enter for the next level" % [gained, pad.multiplier, fuel_bonus])


func _make_sound_player(path: String) -> AudioStreamPlayer:
	if not ResourceLoader.exists(path):
		push_warning("Sound not found: " + path)   # the game still runs, just silent
		return null
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	return player


func _crash(reason: String) -> void:
	game_state = GameState.CRASHED
	if lose_player:
		lose_player.play()
	_spawn_explosion(lander.global_position)
	lander.destroy()
	hud.show_message("CRASHED\n%s\nScore: %d\nPress Enter to restart" % [reason.capitalize(), score])


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("continue"):
		return
	if game_state == GameState.LANDED:
		level += 1
		_start_level()
	elif game_state == GameState.CRASHED:
		level = 1
		score = 0
		_start_level()


func _spawn_explosion(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.amount = 60
	p.lifetime = 1.2
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 260.0
	p.gravity = Vector2(0, 200)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = Color("ffb347")
	add_child(p)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


func _load_high_score() -> int:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		return f.get_32()
	return 0


func _save_high_score() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_32(high_score)
