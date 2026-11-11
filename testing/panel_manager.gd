extends Control

signal closed

var panels: Array[PanelContainer] = []

@onready var gameplay_button: Button = %GameplayButton
@onready var graphics_button: Button = %GraphicsButton
@onready var audio_button: Button = %AudioButton
@onready var controls_button: Button = %ControlsButton

func _ready() -> void:
	panels = [
		%GameplayPanel, %GraphicsPanel, %AudioPanel, %ControlsPanel
	]

	gameplay_button.pressed.connect(show_panel.bind(panels[0]))
	graphics_button.pressed.connect(show_panel.bind(panels[1]))
	audio_button.pressed.connect(show_panel.bind(panels[2]))
	controls_button.pressed.connect(show_panel.bind(panels[3]))

	show_panel(panels[0])
	gameplay_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X:
		closed.emit()
		get_viewport().set_input_as_handled()

func show_panel(panel_to_show: PanelContainer) -> void:
	for panel in panels:
		panel.hide()

	panel_to_show.show()
