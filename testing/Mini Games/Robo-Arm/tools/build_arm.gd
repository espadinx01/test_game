@tool
extends EditorScript
## Construit la scène du bras à partir du modèle .glb.
## Lancer : ouvrir ce script, puis File > Run (Ctrl+Maj+X).

const MODEL := 'res://Mini Games/Robo-Arm/art/models/robotic_manipulator.glb'
const OUT := 'res://scenes/arm/robot_arm.tscn'
const S := 0.5   # échelle : le modèle est réduit de moitié

# [nom, parent, type, position globale du pivot (mètres), pièces du modèle]
const SPEC := [
	['Base', '', 'static', Vector3(0, 0, 0), ['Cylinder', 'Cylinder_013']],
	['Turret', '', 'pivot', Vector3(0, 0.575, 0), ['Cylinder_006', 'Cylinder_005', 'Cylinder_007']],
	['Shoulder', 'Turret', 'pivot', Vector3(0, 1.375, 0), []],
	['UpperArm', 'Shoulder', 'body', Vector3(0, 1.375, 0), ['Cylinder_004']],
	['Elbow', 'Shoulder', 'pivot', Vector3(0, 3.15, -0.65), []],
	['ForeArm', 'Elbow', 'body', Vector3(0, 3.15, -0.65), ['Cube_003', 'Cube_002']],
	['Wrist', 'Elbow', 'pivot', Vector3(0, 4.35, -2.2), []],
	['Gripper', 'Wrist', 'body', Vector3(0, 4.35, -2.2), ['Cylinder_014']],
]

func _run() -> void:
	var src: Node3D = load(MODEL).instantiate()
	var scale_t := Transform3D(Basis.from_scale(Vector3(S, S, S)), Vector3.ZERO)
	# 1) Position de chaque pièce dans le monde, AVANT de la déplacer
	var part_global := {}
	for spec in SPEC:
		for part_name in spec[4]:
			var part := src.find_child(part_name, true, false) as Node3D
			part.owner = null
			if part == null:
				push_error('Pièce introuvable : ' + part_name)
				return
			part_global[part_name] = scale_t * _global(part)
	# 2) Création des nœuds du bras
	var root := Node3D.new()
	root.name = 'RobotArm'
	var nodes := {}
	var globals := {}
	for spec in SPEC:
		var n: Node3D
		match spec[2]:
			'static': n = StaticBody3D.new()
			'body': n = AnimatableBody3D.new()
			_: n = Node3D.new()
		n.name = spec[0]
		var g := Transform3D(Basis.IDENTITY, spec[3])
		var parent_g := Transform3D.IDENTITY
		var parent: Node = root
		if spec[1] != '':
			parent = nodes[spec[1]]
			parent_g = globals[spec[1]]
		parent.add_child(n)
		n.transform = parent_g.affine_inverse() * g
		nodes[spec[0]] = n
		globals[spec[0]] = g
		for part_name in spec[4]:
			var part := src.find_child(part_name, true, false) as Node3D
			part.get_parent().remove_child(part)
			n.add_child(part)
			part.transform = g.affine_inverse() * part_global[part_name]
	_set_owner(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	ResourceSaver.save(packed, OUT)
	src.free()
	root.free()
	EditorInterface.get_resource_filesystem().scan()
	print('Scène créée : ', OUT)

# Transform global d’un nœud (le modèle n’est pas dans l’arbre de scène)
func _global(n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur is Node3D:
		t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t

func _set_owner(n: Node, o: Node) -> void:
	for c in n.get_children():
		c.owner = o
		_set_owner(c, o)
