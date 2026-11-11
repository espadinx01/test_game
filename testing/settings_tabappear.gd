extends Node

const SETTINGS_SCENE: PackedScene = preload("res://Settings_tabs.tscn")

@onready var settings_button: Button = $Control/MarginContainer/VBoxContainer/Button2

var settings_instance: Control = null

func _ready() -> void:
	settings_button.pressed.connect(open_settings)

func open_settings() -> void:
	if settings_instance != null:
		return # already open
	settings_instance = SETTINGS_SCENE.instantiate()
	settings_instance.closed.connect(close_settings)
	add_child(settings_instance)

func close_settings() -> void:
	if settings_instance:
		settings_instance.queue_free()
		settings_instance = null
