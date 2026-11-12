class_name Cargo
extends RigidBody3D

@export var fragile: bool = false
@export var max_impact_speed: float = 4.0

var is_held: bool = false
var _last_speed: float = 0.0

func _ready() -> void:
	add_to_group('cargo')
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true   # évite de traverser les murs à grande vitesse
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	_last_speed = linear_velocity.length()

func _on_body_entered(_b: Node) -> void:
	if fragile and not is_held and _last_speed > max_impact_speed:
		GameManager.cargo_damaged.emit(self)
