extends Control
## Settings screen: AUDIO, WINDOW and a small GUIDE BOOK.
## Opened by settings_tabappear.gd. Everything is built in code, in the colours of the
## menu picture (near-black background, thin gold lines).
## Needs the 'GameSettings' autoload (res://game_settings.gd).
##
## To change the guide book, edit the `pages` list below.

signal closed

const ART: Texture2D = preload("res://background.jpg")
const COL_BG := Color(0.086, 0.086, 0.078)      # the dark of the menu picture
const COL_GOLD := Color(0.8, 0.667, 0.522)      # its thin gold lines
const COL_TEXT := Color(0.9, 0.87, 0.82)
const COL_SOFT := Color(0.9, 0.87, 0.82, 0.72)
const COL_DIM := Color(0.8, 0.667, 0.522, 0.45)
const SCREEN_MARGIN := Vector2(200, 50)
const LEFT_PANEL_WIDTH := 640.0

var pages: Array[Dictionary] = [
	{
		"title": "THE MENU",
		"intro": "Pick a mission and go. These keys work on the mission screen.",
		"keys": [
			["UP / DOWN", "Choose a mission"],
			["ENTER", "Start the selected mission"],
			["X  or  ESC", "Go back"],
			["BACKSPACE", "Return to the menu from inside any mini-game"],
		],
		"tip": "The mouse works on every menu too.",
	},
	{
		"title": "LUNAR LANDER",
		"intro": "Touch down on a landing pad before the fuel runs out. Smaller pads are worth more points.",
		"keys": [
			["A / D  or  LEFT / RIGHT", "Rotate the lander"],
			["W  or  UP", "Fire the thruster (uses fuel)"],
			["ENTER", "Next level after a landing, retry after a crash"],
		],
		"tip": "Land slowly and upright. If a speed or tilt number turns red, you are going too fast or leaning too much.",
	},
	{
		"title": "ROBO-ARM",
		"intro": "Grab the cargo with the gripper and set it down on the green zone. Hold it still for a moment to deliver it.",
		"keys": [
			["A / D", "Turn the arm left / right"],
			["W / S", "Raise / lower the shoulder"],
			["UP / DOWN", "Bend the elbow"],
			["Q / E", "Tilt the wrist"],
			["SPACE", "Grab / release the cargo (stay close to it)"],
			["R", "Restart the level"],
		],
		"tip": "Release the cargo gently and keep it upright and still on the zone. The zone turns bright green when it counts.",
	},
]

var _gs = null   # the GameSettings autoload
var _page := 0
var _first_focus: Control = null
var _page_holder: VBoxContainer
var _page_title: Label
var _page_intro: Label
var _page_keys: VBoxContainer
var _page_tip: Label
var _page_counter: Label
var _size_prev: Button
var _size_next: Button
var _size_value: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().gui_release_focus()   # the menu buttons behind must not react to keys
	_gs = get_node_or_null("/root/GameSettings")
	_build_background()

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(SCREEN_MARGIN.x))
	margin.add_theme_constant_override("margin_right", int(SCREEN_MARGIN.x))
	margin.add_theme_constant_override("margin_top", int(SCREEN_MARGIN.y))
	margin.add_theme_constant_override("margin_bottom", int(SCREEN_MARGIN.y))

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 26)
	margin.add_child(root)
	root.add_child(_build_header())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 40)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	if _gs == null:
		body.add_child(_build_setup_warning())
	else:
		body.add_child(_build_settings_panel())
	body.add_child(_build_guide_panel())

	root.add_child(_build_footer())
	_show_page(0)
	if _first_focus:
		_first_focus.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") \
			or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X):
		closed.emit()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_PAGEDOWN:
		_show_page(_page + 1)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_PAGEUP:
		_show_page(_page - 1)
	else:
		return
	get_viewport().set_input_as_handled()


# ---------- building the screen ----------

func _build_background() -> void:
	var dim := ColorRect.new()   # solid dark: hides the menu behind (it still blocks clicks)
	dim.color = COL_BG
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The picture from the main menu on both sides (the right one mirrored).
	var view := get_viewport_rect().size
	var art_w := view.y * ART.get_width() / float(ART.get_height())
	for side in 2:
		var art := TextureRect.new()
		art.texture = ART
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.flip_h = side == 1
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
		if side == 0:
			art.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
			art.offset_right = art_w
		else:
			art.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
			art.offset_left = -art_w


func _build_header() -> Control:
	var row := HBoxContainer.new()

	var back := Button.new()
	back.text = "< BACK"
	back.focus_mode = Control.FOCUS_NONE   # for mouse users, like the mission screen
	back.custom_minimum_size = Vector2(180, 56)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_button(back, 24)
	back.pressed.connect(func(): closed.emit())
	row.add_child(back)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(center)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 24)
	center.add_child(title_row)
	title_row.add_child(_star(34.0))
	title_row.add_child(_label("SETTINGS", 64, COL_GOLD))
	title_row.add_child(_star(34.0))

	var spacer := Control.new()   # balances the back button so the title is really centred
	spacer.custom_minimum_size = Vector2(180, 0)
	row.add_child(spacer)
	return row


func _build_settings_panel() -> Control:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(LEFT_PANEL_WIDTH, 0)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)

	box.add_child(_section_title("AUDIO"))
	box.add_child(_divider())
	box.add_child(_slider_row("MASTER", _gs.master_volume, Callable(_gs, "set_master_volume")))
	box.add_child(_slider_row("MUSIC", _gs.music_volume, Callable(_gs, "set_music_volume")))
	box.add_child(_slider_row("EFFECTS", _gs.sfx_volume, Callable(_gs, "set_sfx_volume")))

	box.add_child(_gap(30))
	box.add_child(_section_title("WINDOW"))
	box.add_child(_divider())
	box.add_child(_mode_row())
	box.add_child(_size_row())
	return panel


func _build_setup_warning() -> Control:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(LEFT_PANEL_WIDTH, 0)
	var msg := _label("One setup step is missing.\n\nOpen  Project > Project Settings > Globals > Autoload,\nadd  res://game_settings.gd  with the name  GameSettings,\nthen run the game again.", 24, COL_TEXT)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(msg)
	return panel


func _build_guide_panel() -> Control:
	var panel := _make_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	box.add_child(_section_title("GUIDE BOOK"))
	box.add_child(_divider())

	# Everything inside this holder is replaced when the page turns.
	_page_holder = VBoxContainer.new()
	_page_holder.add_theme_constant_override("separation", 14)
	_page_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_page_holder)

	_page_title = _label("", 40, COL_TEXT)
	_page_holder.add_child(_page_title)
	_page_intro = _label("", 22, COL_SOFT)
	_page_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page_holder.add_child(_page_intro)
	_page_keys = VBoxContainer.new()
	_page_keys.add_theme_constant_override("separation", 10)
	_page_holder.add_child(_page_keys)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_holder.add_child(fill)
	_page_tip = _label("", 22, COL_GOLD)
	_page_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page_holder.add_child(_page_tip)

	# page turner:  <   1 / 3   >
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 24)
	box.add_child(nav)
	var prev := _small_button("<")
	prev.pressed.connect(_turn_page.bind(-1))
	nav.add_child(prev)
	_page_counter = _label("", 24, COL_GOLD)
	_page_counter.custom_minimum_size = Vector2(120, 0)
	_page_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nav.add_child(_page_counter)
	var next := _small_button(">")
	next.pressed.connect(_turn_page.bind(1))
	nav.add_child(next)
	return panel


func _build_footer() -> Control:
	var hint := _label("X or ESC : back          PAGE UP / PAGE DOWN : turn the page", 22, COL_TEXT)
	hint.modulate.a = 0.55
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return hint


# ---------- rows ----------

func _row(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var name_label := _label(text, 26, COL_TEXT)
	name_label.custom_minimum_size = Vector2(130, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)
	return row


func _slider_row(text: String, value: float, setter: Callable) -> Control:
	var row := _row(text)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = round(value * 100.0)   # set before connecting: no signal fired
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(0, 32)
	_style_slider(slider)
	row.add_child(slider)

	var pct := _label("%d%%" % int(slider.value), 26, COL_GOLD)
	pct.custom_minimum_size = Vector2(80, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(pct)

	slider.value_changed.connect(_on_slider_changed.bind(pct, setter))
	if _first_focus == null:
		_first_focus = slider
	return row


func _mode_row() -> Control:
	var row := _row("MODE")
	var group := ButtonGroup.new()
	for full in [false, true]:
		var b := Button.new()
		b.text = "FULLSCREEN" if full else "WINDOWED"
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = (_gs.fullscreen == full)
		b.custom_minimum_size = Vector2(190, 52)
		_style_button(b, 22)
		b.pressed.connect(_on_mode_pressed.bind(full))
		row.add_child(b)
	return row


func _size_row() -> Control:
	var row := _row("SIZE")
	_size_prev = _small_button("<")
	_size_prev.pressed.connect(_on_size_step.bind(-1))
	row.add_child(_size_prev)
	_size_value = _label("", 24, COL_TEXT)
	_size_value.custom_minimum_size = Vector2(190, 0)
	_size_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_size_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_size_value)
	_size_next = _small_button(">")
	_size_next.pressed.connect(_on_size_step.bind(1))
	row.add_child(_size_next)
	_refresh_size_row()
	return row


func _key_row(keys: String, desc: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)

	var chip := PanelContainer.new()   # the key name in a little gold outline
	chip.custom_minimum_size = Vector2(300, 0)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(COL_GOLD, 0.10)
	sb.border_color = Color(COL_GOLD, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	chip.add_theme_stylebox_override("panel", sb)
	var key_label := _label(keys, 21, COL_GOLD)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(key_label)
	row.add_child(chip)

	var text := _label(desc, 22, COL_TEXT)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size = Vector2(150, 0)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(text)
	return row


# ---------- reacting ----------

func _on_slider_changed(value: float, pct: Label, setter: Callable) -> void:
	pct.text = "%d%%" % int(value)
	setter.call(value / 100.0)


func _on_mode_pressed(full: bool) -> void:
	_gs.set_fullscreen(full)
	_refresh_size_row()


func _on_size_step(direction: int) -> void:
	_gs.step_window_size(direction)
	_refresh_size_row()


func _refresh_size_row() -> void:
	var s: Vector2i = _gs.window_size
	var locked: bool = _gs.fullscreen   # the size only matters in a window
	_size_value.text = "%d x %d" % [s.x, s.y]
	_size_value.modulate.a = 0.4 if locked else 1.0
	_size_prev.disabled = locked
	_size_next.disabled = locked


func _turn_page(direction: int) -> void:
	_show_page(_page + direction)


func _show_page(i: int) -> void:
	_page = wrapi(i, 0, pages.size())
	var page := pages[_page]
	_page_title.text = page["title"]
	_page_intro.text = page["intro"]
	_page_tip.text = page["tip"]
	_page_counter.text = "%d / %d" % [_page + 1, pages.size()]
	for child in _page_keys.get_children():
		_page_keys.remove_child(child)
		child.queue_free()
	for entry in page["keys"]:
		_page_keys.add_child(_key_row(entry[0], entry[1]))
	_page_holder.modulate.a = 0.0   # quick fade-in, like turning a page
	create_tween().tween_property(_page_holder, "modulate:a", 1.0, 0.18)


# ---------- look ----------

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _section_title(text: String) -> Label:
	return _label(text, 34, COL_GOLD)


func _gap(height: float) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(0, height)
	return g


func _star(size_px: float) -> Control:
	var s := StarMark.new(size_px)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return s


func _line() -> ColorRect:
	var l := ColorRect.new()
	l.color = COL_DIM
	l.custom_minimum_size = Vector2(0, 2)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _divider() -> Control:   # a thin gold line with a small star in the middle
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_line())
	row.add_child(_star(18.0))
	row.add_child(_line())
	return row


func _make_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(COL_BG, 0.9)
	sb.border_color = COL_GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	sb.set_content_margin_all(30)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _box(fill: Color, border: Color = COL_GOLD) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _style_button(b: Button, font_size: int) -> void:
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", COL_GOLD)
	b.add_theme_color_override("font_hover_color", COL_TEXT)
	b.add_theme_color_override("font_focus_color", COL_TEXT)
	b.add_theme_color_override("font_pressed_color", COL_BG)
	b.add_theme_color_override("font_hover_pressed_color", COL_BG)
	b.add_theme_color_override("font_disabled_color", COL_DIM)
	b.add_theme_stylebox_override("normal", _box(Color(COL_GOLD, 0.0)))
	b.add_theme_stylebox_override("hover", _box(Color(COL_GOLD, 0.16)))
	b.add_theme_stylebox_override("pressed", _box(COL_GOLD))
	b.add_theme_stylebox_override("hover_pressed", _box(COL_GOLD.lightened(0.12)))
	b.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), COL_TEXT))
	b.add_theme_stylebox_override("disabled", _box(Color(0, 0, 0, 0), COL_DIM))


func _small_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(56, 52)
	_style_button(b, 24)
	return b


func _style_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()   # the whole bar
	track.bg_color = Color(COL_GOLD, 0.25)
	track.set_corner_radius_all(3)
	track.content_margin_top = 3     # these margins make the bar 6 px thick
	track.content_margin_bottom = 3
	var filled := StyleBoxFlat.new()   # the part left of the knob
	filled.bg_color = COL_GOLD
	filled.set_corner_radius_all(3)
	filled.content_margin_top = 3
	filled.content_margin_bottom = 3
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", filled)
	s.add_theme_stylebox_override("grabber_area_highlight", filled)
	s.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var knob := _circle(13, COL_GOLD)
	var knob_hover := _circle(13, COL_TEXT)
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob_hover)
	s.add_theme_icon_override("grabber_disabled", knob)


func _circle(radius: int, color: Color) -> ImageTexture:
	var d := radius * 2
	var img := Image.create_empty(d, d, false, Image.FORMAT_RGBA8)
	var c := Vector2(radius - 0.5, radius - 0.5)
	for y in d:
		for x in d:
			var alpha := clampf(radius - Vector2(x, y).distance_to(c), 0.0, 1.0)   # soft 1 px edge
			img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	return ImageTexture.create_from_image(img)


## A small four-pointed star, like the sparkles in the menu picture.
class StarMark extends Control:
	var color := Color(0.8, 0.667, 0.522)

	func _init(size_px: float = 28.0) -> void:
		custom_minimum_size = Vector2(size_px, size_px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		var k := r * 0.22
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(0, -r), c + Vector2(k, -k), c + Vector2(r, 0), c + Vector2(k, k),
			c + Vector2(0, r), c + Vector2(-k, k), c + Vector2(-r, 0), c + Vector2(-k, -k),
		]), color)
