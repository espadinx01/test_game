extends Node
## Autoload 'Hub': press BACKSPACE inside any mini-game to return to the menu.

const MENU_PATH := 'res://world.tscn'
const BACK_KEY := KEY_BACKSPACE

var _hint_layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps working when a game is paused
	_hint_layer = CanvasLayer.new()
	_hint_layer.layer = 100
	add_child(_hint_layer)
	var hint := Label.new()
	hint.text = 'BACKSPACE : back to menu'
	hint.modulate = Color(1, 1, 1, 0.55)
	hint.add_theme_font_size_override('font_size', 20)
	hint.position = Vector2(24, get_viewport().get_visible_rect().size.y - 44)
	_hint_layer.add_child(hint)


func _process(_delta: float) -> void:
	_hint_layer.visible = not _in_menu()


func _in_menu() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path == MENU_PATH


func _input(event: InputEvent) -> void:
	if _in_menu():
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == BACK_KEY:
		go_to_menu()
		get_viewport().set_input_as_handled()


func go_to_menu() -> void:
	get_tree().paused = false
	# Robo-Arm keeps its state in the GameManager autoload: reset it.
	var gm := get_node_or_null('/root/GameManager')
	if gm:
		gm.running = false
		gm.elapsed = 0.0
		gm.collisions = 0
		gm.config = null
	get_tree().change_scene_to_file(MENU_PATH)
