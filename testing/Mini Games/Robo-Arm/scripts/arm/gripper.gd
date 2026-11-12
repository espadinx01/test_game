class_name Gripper
extends AnimatableBody3D

signal cargo_grabbed(cargo: Cargo)
signal cargo_released(cargo: Cargo)

enum State { OPEN, HOLDING }

@export var grab_area: Area3D
@export var grab_point: Marker3D
@export var max_grab_distance: float = 0.35
@export var use_joint: bool = false  # false : cargo rigide ; true : cargo qui se balance

var state: State = State.OPEN
var held: Cargo = null
var velocity: Vector3 = Vector3.ZERO  # vitesse de la pince (pour l’élan au lâcher)
var _joint: PinJoint3D = null
var _grab_offset: Transform3D
var _prev_pos: Vector3

func _ready() -> void:
	_prev_pos = global_position
	print('Gripper prêt | grab_area=', grab_area, ' | grab_point=', grab_point)

func toggle() -> void:
	if state == State.OPEN:
		_try_grab()
	else:
		release()

func _try_grab() -> void:
	var best: Cargo = null
	var best_d := INF
	for body in grab_area.get_overlapping_bodies():
		if body is Cargo:
			var d := body.global_position.distance_to(grab_point.global_position)
			if d <= max_grab_distance and d < best_d:
				best = body
				best_d = d
	if best == null:
		return
	held = best
	held.is_held = true
	state = State.HOLDING
	if use_joint:
		_attach_joint(best)
	else:
		_attach_rigid(best)
	cargo_grabbed.emit(best)

func release() -> void:
	if held == null:
		return
	var c := held
	if _joint:
		_joint.queue_free()
		_joint = null
	else:
		c.freeze = false
		c.linear_velocity = velocity  # le cargo garde l’élan de la pince
	c.is_held = false
	held = null
	state = State.OPEN
	cargo_released.emit(c)

func _attach_rigid(c: Cargo) -> void:
	c.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	c.freeze = true
	_grab_offset = grab_point.global_transform.affine_inverse() * c.global_transform

func _attach_joint(c: Cargo) -> void:
	var j := PinJoint3D.new()
	add_child(j)
	j.global_position = grab_point.global_position
	j.node_a = j.get_path_to(self)
	j.node_b = j.get_path_to(c)
	_joint = j

func _physics_process(delta: float) -> void:
	velocity = (global_position - _prev_pos) / delta
	_prev_pos = global_position
	if state == State.HOLDING and held and not use_joint:
		held.global_transform = grab_point.global_transform * _grab_offset

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
	and event.physical_keycode == KEY_SPACE:
		toggle()
