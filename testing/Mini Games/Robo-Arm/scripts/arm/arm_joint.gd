class_name ArmJoint
extends Node3D
## Articulation du bras : rotation autour d’un axe, avec inertie réglable.

signal limit_reached

@export var axis: Vector3 = Vector3.UP
@export var min_angle_deg: float = -180.0
@export var max_angle_deg: float = 180.0
@export var max_speed_deg: float = 60.0      # vitesse maximale (degrés/s)
@export var acceleration_deg: float = 200.0  # deg/s² quand on pousse
@export var deceleration_deg: float = 200.0  # deg/s² quand on relâche
@export var instant: bool = false            # true = aucune inertie (niveau 1)

var input: float = 0.0        # ordre du joueur, entre -1 et 1
var angle_deg: float = 0.0    # angle actuel (0 = pose du modèle)
var velocity_deg: float = 0.0 # vitesse actuelle
var load_factor: float = 1.0  # > 1 quand le bras porte une charge lourde

func _physics_process(delta: float) -> void:
	var target_speed := input * max_speed_deg
	if instant:
		velocity_deg = target_speed
	else:
		var rate := acceleration_deg if absf(input) > 0.01 else deceleration_deg
		velocity_deg = move_toward(velocity_deg, target_speed, rate / load_factor * delta)
	angle_deg += velocity_deg * delta
	if angle_deg < min_angle_deg or angle_deg > max_angle_deg:
		if absf(velocity_deg) > 1.0:
			limit_reached.emit()
		angle_deg = clampf(angle_deg, min_angle_deg, max_angle_deg)
		velocity_deg = 0.0
	_apply()

func set_angle_immediate(a: float) -> void:
	angle_deg = a
	_apply()

func stopping_angle_deg() -> float:
	## Angle parcouru avant l’arrêt si on relâche maintenant : v² / (2a)
	var a := maxf(deceleration_deg / load_factor, 0.001)
	return signf(velocity_deg) * velocity_deg * velocity_deg / (2.0 * a)

func _apply() -> void:
	basis = Basis(axis.normalized(), deg_to_rad(angle_deg))
