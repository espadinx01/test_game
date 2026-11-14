extends Control
## Mini-game picker, Friday Night Funkin' "week select" style.
## To add a game: add one entry to `games` below. Nothing else changes.

signal closed

const SHEET: Texture2D = preload('res://a_clean_transparent_png_style_ui_asset_sheet_on_a.png')
const BAR_NORMAL := Rect2(187, 582, 805, 100)    # dark bar of your UI sheet
const BAR_SELECTED := Rect2(187, 456, 805, 101)  # glowing bar of your UI sheet
const ITEM_SIZE := Vector2(860, 108)
const BAND_HEIGHT := 170.0
const PANEL_SIZE := Vector2(770, 660)
const START_SOUND_PATH := 'res://sounds/general/choose a game.wav'   # <-- put your sound file path here
const LAUNCH_TIME := 0.38                      # seconds the sparkle effect lasts
const FLASH_TIME := 0.12                       # final flash (LAUNCH_TIME + FLASH_TIME = total wait)
const FLASH_COLOR := Color(0.75, 0.9, 1.0)     # quick flash just before the game starts

var games: Array[Dictionary] = [
	{
		'title': 'Lunar Lander',
		'scene': 'res://Mini Games/lunar_lander/Main.tscn',
		'color': Color(0.30, 0.62, 1.00),
		'thumbnail': '',   # optional: 'res://some_screenshot.png'
		'description': 'Guide the lander onto a landing pad with limited fuel. Gentle, level touchdowns on small pads score the most.',
		'controls': 'A / D  or  LEFT / RIGHT : rotate\nW  or  UP : thrust\nENTER : next level / retry',
		'score_file': 'user://highscore.save',
	},
	{
		'title': 'Robo-Arm',
		'scene': 'res://Mini Games/Robo-Arm/scenes/levels/level_test.tscn',
		'color': Color(1.00, 0.55, 0.15),
		'thumbnail': '',
		'description': 'Pilot a robotic arm, grab the cargo with the gripper and set it down on the green drop zone.',
		'controls': 'A / D : turn          W / S : shoulder\nUP / DOWN : elbow          Q / E : wrist\nSPACE : grip / release          R : restart',
		'score_file': '',
	},
]

var _index := 0
var _locked := false
var _tween: Tween
var _tex_normal: AtlasTexture
var _tex_selected: AtlasTexture
var _items: Array[Control] = []
var _bars: Array[TextureRect] = []
var _band: ColorRect
var _band_game: Label
var _panel: PanelContainer
var _thumb: ColorRect
var _thumb_tex: TextureRect
var _thumb_label: Label
var _desc: Label
var _controls: Label
var _best: Label
var _fade: ColorRect
var _spark_tex: GradientTexture2D
var _spark_ramp: Gradient


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().gui_release_focus()   # the menu buttons behind must not react to keys
	_tex_normal = _atlas(BAR_NORMAL)
	_tex_selected = _atlas(BAR_SELECTED)
	_make_spark_assets()
	_build_background()
	_build_list()
	_build_preview()
	_build_footer()
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_select(0, false)
	create_tween().tween_property(_fade, 'color:a', 0.0, 0.25)   # fade in


func _atlas(region: Rect2) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = SHEET
	t.region = region
	return t


# ---------- building the screen ----------

func _build_background() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.07, 0.95)   # hides the menu behind (it still blocks clicks)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_band = ColorRect.new()   # the colored band at the top, like FNF
	add_child(_band)
	_band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_band.offset_bottom = BAND_HEIGHT
	var title := _band_label('SELECT A MISSION', HORIZONTAL_ALIGNMENT_LEFT)
	title.offset_left = 60
	_band_game = _band_label('', HORIZONTAL_ALIGNMENT_RIGHT)
	_band_game.offset_right = -60


func _band_label(text: String, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override('font_size', 54)
	l.add_theme_color_override('font_shadow_color', Color(0, 0, 0, 0.55))
	l.add_theme_constant_override('shadow_offset_x', 3)
	l.add_theme_constant_override('shadow_offset_y', 3)
	_band.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return l


func _build_list() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override('separation', 30)
	add_child(box)
	for i in games.size():
		box.add_child(_make_item(games[i]['title'], i))
	var view := get_viewport_rect().size
	var total := ITEM_SIZE.y * games.size() + 30.0 * (games.size() - 1)
	box.position = Vector2(110, BAND_HEIGHT + (view.y - BAND_HEIGHT - total) / 2.0)
	box.size = Vector2(ITEM_SIZE.x, total)


func _make_item(title: String, i: int) -> Control:
	var item := Control.new()
	item.custom_minimum_size = ITEM_SIZE
	item.pivot_offset = Vector2(0, ITEM_SIZE.y / 2.0)   # scale from the left edge
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.mouse_entered.connect(_select.bind(i))
	item.gui_input.connect(_on_item_gui_input.bind(i))

	var bar := TextureRect.new()
	bar.texture = _tex_normal
	bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bar.stretch_mode = TextureRect.STRETCH_SCALE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var label := Label.new()
	label.text = title.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override('font_size', 46)
	label.add_theme_color_override('font_shadow_color', Color(0, 0, 0, 0.6))
	label.add_theme_constant_override('shadow_offset_x', 3)
	label.add_theme_constant_override('shadow_offset_y', 3)
	item.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_items.append(item)
	_bars.append(bar)
	return item


func _build_preview() -> void:
	var view := get_viewport_rect().size
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.15, 0.92)
	sb.border_color = Color(0.35, 0.65, 1.0, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	_panel.add_theme_stylebox_override('panel', sb)
	add_child(_panel)
	_panel.size = PANEL_SIZE
	_panel.position = Vector2(view.x - PANEL_SIZE.x - 110,
			BAND_HEIGHT + (view.y - BAND_HEIGHT - PANEL_SIZE.y) / 2.0)

	var margin := MarginContainer.new()
	for side in ['left', 'top', 'right', 'bottom']:
		margin.add_theme_constant_override('margin_' + side, 28)
	_panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override('separation', 18)
	margin.add_child(col)

	_thumb = ColorRect.new()   # colored placeholder; shows a screenshot if 'thumbnail' is set
	_thumb.custom_minimum_size = Vector2(0, 300)
	_thumb.clip_contents = true
	col.add_child(_thumb)
	_thumb_tex = TextureRect.new()
	_thumb_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thumb_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_thumb.add_child(_thumb_tex)
	_thumb_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_thumb_label = Label.new()
	_thumb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thumb_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_thumb_label.add_theme_font_size_override('font_size', 64)
	_thumb.add_child(_thumb_label)
	_thumb_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_desc = _info_label(26, Color(1, 1, 1))
	_controls = _info_label(22, Color(0.65, 0.85, 1.0))
	_best = _info_label(24, Color(1.0, 0.85, 0.35))
	col.add_child(_desc)
	col.add_child(_controls)
	col.add_child(_best)


func _info_label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override('font_size', font_size)
	l.add_theme_color_override('font_color', color)
	return l


func _build_footer() -> void:
	var hint := Label.new()
	hint.text = 'UP / DOWN : choose          ENTER : play          X or ESC : back'
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override('font_size', 24)
	hint.modulate = Color(1, 1, 1, 0.6)
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -80
	hint.offset_bottom = -30

	var back := Button.new()   # for mouse users
	back.text = '< BACK'
	back.flat = true
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override('font_size', 26)
	back.pressed.connect(func(): closed.emit())
	add_child(back)
	back.position = Vector2(40, BAND_HEIGHT + 20)


# ---------- selection ----------

func _select(i: int, animate := true) -> void:
	if _locked:
		return
	if animate and i == _index:
		return
	_index = i
	var entry := games[i]
	var dur := 0.22 if animate else 0.0

	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for k in _items.size():
		var sel := k == i
		_bars[k].texture = _tex_selected if sel else _tex_normal
		_tween.tween_property(_items[k], 'scale', Vector2.ONE * (1.05 if sel else 1.0), dur)
		_tween.tween_property(_items[k], 'modulate:a', 1.0 if sel else 0.6, dur)

	var color: Color = entry['color']
	_tween.tween_property(_band, 'color', color, dur)
	_tween.tween_property(_thumb, 'color', color.darkened(0.55), dur)
	_panel.modulate.a = 0.35
	_tween.tween_property(_panel, 'modulate:a', 1.0, dur)

	_band_game.text = String(entry['title']).to_upper()
	_thumb_label.text = String(entry['title']).to_upper()
	_desc.text = entry['description']
	_controls.text = entry['controls']

	var thumb_path: String = entry.get('thumbnail', '')
	var has_thumb := thumb_path != '' and ResourceLoader.exists(thumb_path)
	_thumb_tex.visible = has_thumb
	_thumb_label.visible = not has_thumb
	if has_thumb:
		_thumb_tex.texture = load(thumb_path)

	var best := _best_score(entry.get('score_file', ''))
	_best.text = ('BEST SCORE : %d' % best) if best >= 0 else ''


func _best_score(path: String) -> int:
	if path != '' and FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f:
			return f.get_32()
	return -1


# ---------- input ----------

func _input(event: InputEvent) -> void:
	if _locked:
		return
	if event.is_action_pressed('ui_down'):
		_select((_index + 1) % games.size())
	elif event.is_action_pressed('ui_up'):
		_select((_index - 1 + games.size()) % games.size())
	elif event.is_action_pressed('ui_accept'):
		_play(_index)
	elif event.is_action_pressed('ui_cancel') \
			or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X):
		closed.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func _on_item_gui_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_select(i)
		_play(i)


func _play(i: int) -> void:
	var path: String = games[i]['scene']
	if not ResourceLoader.exists(path):
		push_warning('Game scene not found: ' + path)
		return
	_locked = true   # ignore keys, clicks and hovering while the launch effect plays
	var color: Color = games[i]['color']

	if ResourceLoader.exists(START_SOUND_PATH):
		var player := AudioStreamPlayer.new()
		player.stream = load(START_SOUND_PATH)
		get_tree().root.add_child(player)   # lives in the root: not cut when the scene changes
		player.finished.connect(player.queue_free)
		player.play()

	_launch_effect(i, color)
	await get_tree().create_timer(LAUNCH_TIME).timeout

	# quick bright flash, then the game starts
	_fade.color = Color(FLASH_COLOR.r, FLASH_COLOR.g, FLASH_COLOR.b, 0.0)
	var tw := create_tween()
	tw.tween_property(_fade, 'color:a', 1.0, FLASH_TIME)
	await tw.finished
	get_tree().change_scene_to_file(path)


# ---------- launch effect (stays on the selection screen) ----------

func _launch_effect(i: int, color: Color) -> void:
	if _tween:
		_tween.kill()
	for k in _items.size():
		if k != i:
			create_tween().tween_property(_items[k], 'modulate:a', 0.15, 0.15)   # dim the others
	var item := _items[i]
	var pulse := create_tween().set_loops()   # the chosen bar pulses and flashes
	pulse.tween_property(item, 'scale', Vector2.ONE * 1.12, 0.09)
	pulse.parallel().tween_property(item, 'modulate', Color(1.8, 1.8, 2.0), 0.09)
	pulse.tween_property(item, 'scale', Vector2.ONE * 1.05, 0.09)
	pulse.parallel().tween_property(item, 'modulate', Color.WHITE, 0.09)
	_sparkle_burst(item.global_position + item.size * 0.5, color, 90)
	var sparkles := create_tween().set_loops()   # small sparkles all over the screen
	sparkles.tween_callback(_random_sparkle.bind(color)).set_delay(0.04)


func _random_sparkle(color: Color) -> void:
	var view := get_viewport_rect().size
	_sparkle_burst(Vector2(randf_range(120.0, view.x - 120.0),
			randf_range(BAND_HEIGHT + 40.0, view.y - 120.0)), color, 14)


func _sparkle_burst(pos: Vector2, color: Color, amount: int) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.texture = _spark_tex
	p.color = Color.WHITE.lerp(color, 0.45)
	p.color_ramp = _spark_ramp
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.35
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 120)
	p.initial_velocity_min = 200.0
	p.initial_velocity_max = 600.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 1.1
	add_child(p)
	p.emitting = true
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)


func _make_spark_assets() -> void:
	var g := Gradient.new()   # soft glowing dot (white in the middle, transparent at the edge)
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	_spark_tex = GradientTexture2D.new()
	_spark_tex.gradient = g
	_spark_tex.width = 32
	_spark_tex.height = 32
	_spark_tex.fill = GradientTexture2D.FILL_RADIAL
	_spark_tex.fill_from = Vector2(0.5, 0.5)
	_spark_tex.fill_to = Vector2(0.5, 0.0)
	_spark_ramp = Gradient.new()   # fades each sparkle out over its life
	_spark_ramp.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
