class_name LevelConfig
extends Resource

@export var title: String = 'Niveau 1'
@export var scene: PackedScene
@export_enum('Simple', 'Avancé') var control_mode: int = 1
@export var instant_joints: bool = true
@export var max_speed_deg: float = 60.0
@export var acceleration_deg: float = 200.0
@export var deceleration_deg: float = 200.0
@export var cargo_mass: float = 5.0
@export var use_swing_joint: bool = false
@export var drop_tolerance: float = 0.5
@export var par_time: float = 60.0    # temps de référence pour les étoiles
@export var time_limit: float = 0.0   # 0 = illimité
@export var max_collisions: int = 99
