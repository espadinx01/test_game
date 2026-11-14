extends Node3D

@onready var arm: RobotArm = $RobotArm
@onready var drop_zone: DropZone = $DropZone
@onready var cargo: Cargo = $Cargo

func _ready() -> void:
	# Permet de lancer ce niveau directement avec F6, sans passer par un menu.
	if GameManager.config == null:
		GameManager.config = LevelConfig.new()
	var cfg := GameManager.config
	arm.apply_config(cfg)
	cargo.mass = cfg.cargo_mass
	drop_zone.max_offset = cfg.drop_tolerance
	drop_zone.delivered.connect(func(_c): GameManager.complete())
	GameManager.begin()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
		and event.physical_keycode == KEY_R:
		GameManager.restart()
