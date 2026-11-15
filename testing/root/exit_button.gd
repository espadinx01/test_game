extends Button
## Attach this script to the 'Exit' button of world.tscn (Button4).
## It closes the game. Same idea as start_button.gd, just simpler.


func _ready() -> void:
	pressed.connect(quit_game)


func quit_game() -> void:
	# get_tree().quit() skips the normal "window closed" step, so save the settings first.
	var settings := get_node_or_null("/root/GameSettings")
	if settings:
		settings.save()
	get_tree().quit()
