class_name RobotArm
extends Node3D

enum ControlMode { SIMPLE, ADVANCED }

@export var control_mode: ControlMode = ControlMode.ADVANCED
@export var turret: ArmJoint
@export var shoulder: ArmJoint
@export var elbow: ArmJoint
@export var wrist: ArmJoint
@export var gripper: Gripper
@export var load_influence: float = 0.15  # effet de la masse du cargo sur l’inertie

@onready var joints: Array[ArmJoint] = [turret, shoulder, elbow, wrist]

func _ready() -> void:
	gripper.cargo_grabbed.connect(_on_cargo_grabbed)
	gripper.cargo_released.connect(_on_cargo_released)

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
