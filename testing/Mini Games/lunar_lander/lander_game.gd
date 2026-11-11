class_name Lander
extends RigidBody2D

signal touched_ground(impact_velocity: Vector2)

const FOOT_HALF_WIDTH := 27.0   # half the width of the feet
const FOOT_OFFSET := 22.0       # distance from centre to the feet

@export var thrust_force := 420.0       # px/s² with mass 1 (gravity is 150)
@export var rotation_speed := 2.4       # radians per second
@export var max_fuel := 1000.0
@export var fuel_use_per_second := 55.0

var fuel := max_fuel
var active := true          # false after landing or crashing
var thrusting := false
var impact_velocity := Vector2.ZERO

@onready var flame: Polygon2D = $Visuals/Flame
@onready var exhaust: CPUParticles2D = $Visuals/Exhaust


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Runs BEFORE collisions are solved, so this is the true impact speed.
	impact_velocity = state.linear_velocity

	thrusting = false
	if not active:
		return

	var turn := Input.get_axis("rotate_left", "rotate_right")
	if turn != 0.0:
		state.angular_velocity = turn * rotation_speed

	if Input.is_action_pressed("thrust") and fuel > 0.0:
		thrusting = true
		state.apply_central_force(Vector2.UP.rotated(rotation) * thrust_force)
		fuel = maxf(fuel - fuel_use_per_second * state.step, 0.0)


func _process(_delta: float) -> void:
	flame.visible = thrusting
	exhaust.emitting = thrusting
	if thrusting:
		flame.scale.y = randf_range(0.7, 1.3)   # flicker


func _on_body_entered(_body: Node) -> void:
	if active:
		touched_ground.emit(impact_velocity)


# Called by Main when the ship explodes.
func destroy() -> void:
	active = false
	thrusting = false
	set_deferred("freeze", true)   # deferred: we're inside a physics callback
	$Visuals.hide()
