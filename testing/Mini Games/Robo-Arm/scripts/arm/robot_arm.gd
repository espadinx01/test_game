class_name RobotArm
extends Node3D

enum ControlMode { SIMPLE, ADVANCED }

@export var control_mode: ControlMode = ControlMode.ADVANCED
@export var turret: ArmJoint
@export var shoulder: ArmJoint
@export var elbow: ArmJoint
@export var wrist: ArmJoint

@onready var joints: Array[ArmJoint] = [turret, shoulder, elbow, wrist]

func _physics_process(_delta: float) -> void:
	_read_input()

func _read_input() -> void:
	turret.input = Input.get_axis('turret_left', 'turret_right')
	var lift := Input.get_axis('arm_down', 'arm_up')
	if control_mode == ControlMode.SIMPLE:
		# Un levier pilote épaule + coude ; le poignet compense pour rester horizontal.
		shoulder.input = lift
		elbow.input = -lift * 1.4
		wrist.input = 0.0
		wrist.angle_deg = -(shoulder.angle_deg + elbow.angle_deg)  # signe à vérifier
	else:
		shoulder.input = lift
		elbow.input = Input.get_axis('elbow_down', 'elbow_up')
		wrist.input = Input.get_axis('wrist_down', 'wrist_up')
