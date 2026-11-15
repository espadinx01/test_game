extends Control
## Credits screen, in the same starry style as the settings screen.
## Opened by credits_button.gd. Everything is built in code.
##
## To change the names on the screen, edit the `members` list below.

signal closed

const ART: Texture2D = preload("res://background.jpg")
const COL_BG := Color(0.086, 0.086, 0.078)      # the dark of the menu picture
const COL_GOLD := Color(0.8, 0.667, 0.522)      # its thin gold lines
const COL_TEXT := Color(0.9, 0.87, 0.82)
const COL_SOFT := Color(0.9, 0.87, 0.82, 0.72)
const COL_DIM := Color(0.8, 0.667, 0.522, 0.45)
const THANKS := "Thank you for playing!"

# The GitHub names shown on the screen. Add or remove lines as you like.
var members: Array[Dictionary] = [
	{"name": "espadinx01"},
	{"name": "Casperjihad-rgb"},
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().gui_release_focus()   # the menu buttons behind must not react to keys
	_build_background()

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(820, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	panel.add_child(box)

	box.add_child(_title_row())
	box.add_child(_divider())
	box.add_child(_made_with_row())
	box.add_child(_members_row())
	box.add_child(_divider())
	var thanks := _label(THANKS, 28, COL_GOLD)
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(thanks)

	_add_back_button()
	_add_hint()

	center.modulate.a = 0.0   # soft fade-in
	create_tween().tween_property(center, "modulate:a", 1.0, 0.3)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") \
			or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X):
		closed.emit()
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


func _title_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	var left := _star(38.0)
	var right := _star(38.0)
	row.add_child(left)
	row.add_child(_label("CREDITS", 72, COL_GOLD))
	row.add_child(right)
	_twinkle(left, 0.9)     # the two stars twinkle at different speeds
	_twinkle(right, 1.3)
	return row


func _made_with_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(_label("Made with", 26, COL_SOFT))
	var heart := HeartMark.new()
	row.add_child(heart)
	row.add_child(_label("by", 26, COL_SOFT))
	var beat := create_tween().set_loops()   # a gentle heartbeat
	beat.tween_property(heart, "scale", Vector2(1.25, 1.25), 0.45).set_trans(Tween.TRANS_SINE)
	beat.tween_property(heart, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)
	return row


func _members_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	for member in members:
		row.add_child(_member_card(member["name"]))
	return row


func _member_card(member_name: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(330, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(COL_GOLD, 0.07)
	sb.border_color = Color(COL_GOLD, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(24)
	card.add_theme_stylebox_override("panel", sb)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)

	var avatar := Avatar.new(member_name.substr(0, 1))   # a round badge with the first letter
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(avatar)
	var caption := _label("GITHUB", 18, COL_GOLD)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(caption)
	var name_label := _label(member_name, 28, COL_TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	return card


func _add_back_button() -> void:
	var back := Button.new()
	back.text = "< BACK"
	back.focus_mode = Control.FOCUS_NONE   # for mouse users, like the mission screen
	back.custom_minimum_size = Vector2(180, 56)
	back.position = Vector2(200, 50)
	_style_button(back, 24)
	back.pressed.connect(func(): closed.emit())
	add_child(back)


func _add_hint() -> void:
	var hint := _label("X or ESC : back", 22, COL_TEXT)
	hint.modulate.a = 0.55
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -70
	hint.offset_bottom = -30


func _twinkle(node: Control, seconds: float) -> void:
	var t := create_tween().set_loops()
	t.tween_property(node, "modulate:a", 0.3, seconds).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "modulate:a", 1.0, seconds).set_trans(Tween.TRANS_SINE)


# ---------- look ----------

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


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
	sb.set_corner_radius_all(24)
	sb.set_content_margin_all(40)
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
	b.add_theme_color_override("font_pressed_color", COL_BG)
	b.add_theme_stylebox_override("normal", _box(Color(COL_GOLD, 0.0)))
	b.add_theme_stylebox_override("hover", _box(Color(COL_GOLD, 0.16)))
	b.add_theme_stylebox_override("pressed", _box(COL_GOLD))
	b.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), COL_TEXT))


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


## A little rose-coloured heart.
class HeartMark extends Control:
	var color := Color(0.93, 0.56, 0.62)

	func _init() -> void:
		custom_minimum_size = Vector2(30, 28)
		pivot_offset = Vector2(15, 14)   # so it grows from its centre when it beats
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var points := PackedVector2Array()
		var c := size / 2.0
		var k := minf(size.x, size.y) / 34.0   # the classic heart curve is about 32 units wide
		for i in 48:
			var t := TAU * i / 48.0
			var x := 16.0 * pow(sin(t), 3)
			var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
			points.append(c + Vector2(x, y - 2.5) * k)   # -2.5 re-centres it vertically
		draw_colored_polygon(points, color)


## A round gold badge with a letter inside.
class Avatar extends Control:
	var letter := "?"
	var color := Color(0.8, 0.667, 0.522)

	func _init(initial: String = "?", size_px: float = 96.0) -> void:
		letter = initial.to_upper()
		custom_minimum_size = Vector2(size_px, size_px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 3.0
		draw_circle(c, r, Color(color, 0.12))
		draw_arc(c, r, 0.0, TAU, 64, color, 2.5, true)
		var font_size := int(r)
		draw_string(ThemeDB.fallback_font, Vector2(0, c.y + font_size * 0.35), letter,
				HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, color)
