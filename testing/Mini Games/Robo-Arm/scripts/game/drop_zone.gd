class_name DropZone
extends Area3D

signal delivered(cargo: Cargo)

@export var max_speed: float = 0.15    # m/s
@export var settle_time: float = 0.8   # secondes d’immobilité requises
@export var max_tilt_deg: float = 10.0
@export var max_offset: float = 0.5    # distance horizontale max au centre
@export var mesh: MeshInstance3D

var _timer: float = 0.0
var _mat: StandardMaterial3D

func _ready() -> void:
	if mesh == null:
		mesh = get_node_or_null('ZoneMesh') as MeshInstance3D
	if mesh:
		_mat = StandardMaterial3D.new()
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = _mat
	else:
		push_warning('DropZone : aucun nœud ZoneMesh trouvé')
	_set_color(Color(0.2, 1.0, 0.3, 0.35))
	body_entered.connect(func(b): print('Zone : entré ', b, ' | est Cargo ? ', b is Cargo))

func _physics_process(delta: float) -> void:
	var inside: Cargo = null
	var valid: Cargo = null
	for body in get_overlapping_bodies():
		if body is Cargo:
			inside = body
			if _is_valid(body):
				valid = body
				break
	_timer = _timer + delta if valid else 0.0
	if valid and _timer >= settle_time:
		_set_color(Color(0.1, 1.0, 0.2, 0.9))   # vert vif : validé
		delivered.emit(valid)
		set_physics_process(false)
	elif inside:
		_set_color(Color(1.0, 0.6, 0.1, 0.6))   # orange : dedans mais pas stable
	else:
		_set_color(Color(0.2, 1.0, 0.3, 0.35))  # vert transparent : vide

func _is_valid(c: Cargo) -> bool:
	var offset := Vector2(c.global_position.x - global_position.x,
			c.global_position.z - global_position.z).length()
	var tilt := rad_to_deg(c.global_basis.y.angle_to(Vector3.UP))
	return (not c.is_held
			and c.linear_velocity.length() < max_speed
			and tilt < max_tilt_deg
			and offset < max_offset)

func _set_color(c: Color) -> void:
	if _mat:
		_mat.albedo_color = c
