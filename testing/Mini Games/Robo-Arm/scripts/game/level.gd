extends Node3D

const WIN_SOUND_PATH := "res://sounds/mini_game2/completion-of-a-level-2063.wav"   # <-- put the exact path of your win sound here

@onready var arm: RobotArm = $RobotArm
@onready var drop_zone: DropZone = $DropZone
@onready var cargo: Cargo = $Cargo

var win_player: AudioStreamPlayer

func _ready() -> void:
	# Permet de lancer ce niveau directement avec F6, sans passer par un menu.
	if GameManager.config == null:
		GameManager.config = LevelConfig.new()
	var cfg := GameManager.config
	arm.apply_config(cfg)
	cargo.mass = cfg.cargo_mass
	drop_zone.max_offset = cfg.drop_tolerance
	drop_zone.delivered.connect(func(_c): GameManager.complete())
	win_player = _make_sound_player(WIN_SOUND_PATH)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.begin()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
		and event.physical_keycode == KEY_R:
		GameManager.restart()


func _on_level_completed(_stats: Dictionary) -> void:
	if win_player:
		win_player.play()


func _make_sound_player(path: String) -> AudioStreamPlayer:
	if not ResourceLoader.exists(path):
		push_warning("Sound not found: " + path)   # the game still runs, just silent
		return null
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	return player
