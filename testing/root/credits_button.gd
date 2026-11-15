extends Button
## Attach this script to the 'Credits' button of world.tscn (Button3).
## It opens the credits screen on top of the menu (same idea as start_button.gd).

const CREDITS_SCENE: PackedScene = preload("res://Credits.tscn")

var _credits: Control = null


func _ready() -> void:
	pressed.connect(open_credits)


func open_credits() -> void:
	if _credits != null:
		return # already open
	_credits = CREDITS_SCENE.instantiate()
	_credits.closed.connect(close_credits)
	# Added to the scene root (the World node), not to the button: the screen
	# must cover the whole window, and a Button would clip and resize it.
	get_tree().current_scene.add_child(_credits)


func close_credits() -> void:
	if _credits:
		_credits.queue_free()
		_credits = null
