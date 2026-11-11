extends CharacterBody3D


@onready var camera: Camera3D = $"../Camera3D"
@onready var character: Node3D = $cute_robot

var ray_origin = Vector3()
var ray_end = Vector3()

var look_at_me = Vector3()

func _physics_process(delta: float) -> void:
	look_at_mouse()


func look_at_mouse():
	var mouse_position = get_viewport().get_mouse_position()
	ray_origin = camera.project_ray_origin(mouse_position)
	ray_end = ray_origin + camera.project_ray_normal(mouse_position) * 2000

	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = ray_origin
	params.to = ray_end

	var intersection = space_state.intersect_ray(params)

	if !intersection.is_empty():
		var pos = intersection.position
		look_at_me = Vector3(pos.x, pos.y, pos.z)

		character.look_at(look_at_me, Vector3.UP)
		character.rotate_object_local(Vector3.UP, PI)
		
