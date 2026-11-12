extends Node

signal level_started(cfg: LevelConfig)
signal level_completed(stats: Dictionary)
signal level_failed(reason: String)
signal collision_happened(count: int)
signal cargo_damaged(cargo: Node)

var levels: Array[LevelConfig] = []
var current_index: int = 0
var config: LevelConfig
var collisions: int = 0
var elapsed: float = 0.0
var running: bool = false

func _ready() -> void:
	cargo_damaged.connect(func(_c): fail('Cargo endommagé !'))
	_load_levels()

func _load_levels() -> void:
	levels.clear()
	var dir := DirAccess.open('res://resources/levels')
	if dir == null:
		return
	var files: Array[String] = []
	for f in dir.get_files():
		files.append(f.trim_suffix('.remap'))  # en export, les .tres sont renommés
	files.sort()
	for f in files:
		if f.ends_with('.tres'):
			levels.append(load('res://resources/levels/' + f) as LevelConfig)

func start_level(index: int) -> void:
	current_index = index
	config = levels[index]
	collisions = 0
	elapsed = 0.0
	running = false
	get_tree().paused = false
	get_tree().change_scene_to_packed(config.scene)

func restart() -> void:
	collisions = 0
	elapsed = 0.0
	running = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func begin() -> void:  # appelé par le niveau une fois chargé
	running = true
	level_started.emit(config)

func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	if config.time_limit > 0.0 and elapsed >= config.time_limit:
		fail('Temps écoulé !')

func register_collision() -> void:
	collisions += 1
	collision_happened.emit(collisions)
	if collisions > config.max_collisions:
		fail('Trop de collisions !')

func complete() -> void:
	if not running:
		return
	running = false
	var stars := 1
	if collisions <= 2:
		stars = 2
	if collisions == 0 and elapsed <= config.par_time:
		stars = 3
	var score := maxi(0, 1000 - int(maxf(0.0, elapsed - config.par_time) * 5.0) - collisions * 50)
	level_completed.emit({'time': elapsed, 'collisions': collisions, 'stars': stars, 'score': score})

func fail(reason: String) -> void:
	if running:
		running = false
		level_failed.emit(reason)
