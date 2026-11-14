class_name RobotArm
extends Node3D

enum ControlMode { SIMPLE, ADVANCED }

const MOTOR_SOUND_PATH := "res://sounds/mini_game2/mini game 2 robot.mp3"   # <-- put the exact path of your joint sound here
const MOTOR_LOOP_START := 0.0     # seconds: where the looped part of the sound begins
const MOTOR_LOOP_END := 1.5       # seconds: where it ends (it jumps back to the start here)
const MOTOR_MIN_SPEED := 2.0      # deg/s: a joint slower than this counts as "not moving"
const MOTOR_FADE_TIME := 0.15     # seconds of fade in / fade out
const MOTOR_VOLUME_DB := -6.0     # volume while moving (0 = full volume)
const MOTOR_SILENT_DB := -40.0    # volume at the bottom of the fade

@export var control_mode: ControlMode = ControlMode.ADVANCED
@export var turret: ArmJoint
@export var shoulder: ArmJoint
@export var elbow: ArmJoint
@export var wrist: ArmJoint
@export var gripper: Gripper
@export var load_influence: float = 0.15  # effet de la masse du cargo sur l’inertie

@onready var joints: Array[ArmJoint] = [turret, shoulder, elbow, wrist]

var motor_player: AudioStreamPlayer
var _motor_on := false
var _motor_tween: Tween

func _ready() -> void:
	gripper.cargo_grabbed.connect(_on_cargo_grabbed)
	gripper.cargo_released.connect(_on_cargo_released)
	motor_player = _make_sound_player(MOTOR_SOUND_PATH)
	if motor_player:
		motor_player.volume_db = MOTOR_SILENT_DB

func _physics_process(_delta: float) -> void:
	_read_input()

func _read_input() -> void:
	turret.input = Input.get_axis('turret_left', 'turret_right')
	var lift := Input.get_axis('arm_down', 'arm_up')
	if control_mode == ControlMode.SIMPLE:
		shoulder.input = lift
		elbow.input = -lift * 1.4
		wrist.input = 0.0
		wrist.angle_deg = -(shoulder.angle_deg + elbow.angle_deg)
	else:
		shoulder.input = lift
		elbow.input = Input.get_axis('elbow_down', 'elbow_up')
		wrist.input = Input.get_axis('wrist_down', 'wrist_up')

func apply_config(cfg: LevelConfig) -> void:
	control_mode = cfg.control_mode as ControlMode
	for j in joints:
		j.instant = cfg.instant_joints
		j.max_speed_deg = cfg.max_speed_deg
		j.acceleration_deg = cfg.acceleration_deg
		j.deceleration_deg = cfg.deceleration_deg
	gripper.use_joint = cfg.use_swing_joint

func _on_cargo_grabbed(c: Cargo) -> void:
	for j in joints:
		j.load_factor = 1.0 + c.mass * load_influence

func _on_cargo_released(_c: Cargo) -> void:
	for j in joints:
		j.load_factor = 1.0


func _process(_delta: float) -> void:
	if motor_player == null:
		return
	var moving := false
	for j in joints:
		if absf(j.velocity_deg) > MOTOR_MIN_SPEED:
			moving = true
			break
	if moving != _motor_on:
		_motor_on = moving
		_fade_motor(moving)
	# Loop only a short part of the sound, not the whole file.
	if _motor_on:
		if not motor_player.playing:
			motor_player.play(MOTOR_LOOP_START)
		elif motor_player.get_playback_position() >= MOTOR_LOOP_END:
			motor_player.seek(MOTOR_LOOP_START)


func _fade_motor(on: bool) -> void:
	if _motor_tween:
		_motor_tween.kill()
	_motor_tween = create_tween()
	if on:
		if not motor_player.playing:
			motor_player.volume_db = MOTOR_SILENT_DB
			motor_player.play(MOTOR_LOOP_START)
		_motor_tween.tween_property(motor_player, "volume_db", MOTOR_VOLUME_DB, MOTOR_FADE_TIME)
	else:
		_motor_tween.tween_property(motor_player, "volume_db", MOTOR_SILENT_DB, MOTOR_FADE_TIME)
		_motor_tween.tween_callback(motor_player.stop)


func _make_sound_player(path: String) -> AudioStreamPlayer:
	if not ResourceLoader.exists(path):
		push_warning("Sound not found: " + path)   # the game still runs, just silent
		return null
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	return player
