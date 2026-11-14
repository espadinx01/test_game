extends Button
## Attach this script to the 'Start Game' button of world.tscn.
## It opens the mini-game picker on top of the menu (same idea as your Settings overlay).

const GAME_SELECT_SCENE: PackedScene = preload('res://game_select.tscn')

var _picker: Control = null


func _ready() -> void:
	pressed.connect(open_picker)


func open_picker() -> void:
	if _picker != null:
		return # already open
	_picker = GAME_SELECT_SCENE.instantiate()
	_picker.closed.connect(close_picker)
	# Added to the scene root (the World node), not to the button: the picker
	# must cover the whole screen, and a Button would clip and resize it.
	get_tree().current_scene.add_child(_picker)


func close_picker() -> void:
	if _picker:
		_picker.queue_free()
		_picker = null
