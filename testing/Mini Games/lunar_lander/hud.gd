
class_name Hud
extends CanvasLayer

const OK_COLOR := Color.WHITE
const BAD_COLOR := Color("ff5a5a")

@onready var score_label: Label = %scoreLabel
@onready var level_label: Label = %LevelLabel
@onready var fuel_bar: ProgressBar = %FuelBar
@onready var alt_label: Label = %AltLabel
@onready var hspeed_label: Label = %HspeedLabel
@onready var vspeed_label: Label = %VSpeedLabel
@onready var angle_label: Label = %AngleLabel
@onready var message_label: Label = %MessageLabel


func set_status(score: int, high_score: int, level: int) -> void:
	score_label.text = "SCORE %d          BEST %d" % [score, high_score]
	level_label.text = "LEVEL %d" % level


func update_stats(fuel: float, max_fuel: float, altitude: float, vel: Vector2,
				  angle: float, h_ok: bool, v_ok: bool, a_ok: bool) -> void:
	fuel_bar.max_value = max_fuel
	fuel_bar.value = fuel
	alt_label.text = "ALTITUDE         %d" % int(altitude)
	hspeed_label.text = "H-SPEED          %d" % int(vel.x)
	vspeed_label.text = "V-SPEED    %d" % int(vel.y)
	angle_label.text = "TILT        %d°" % int(angle)

	hspeed_label.add_theme_color_override("font_color", OK_COLOR if h_ok else BAD_COLOR)
	vspeed_label.add_theme_color_override("font_color", OK_COLOR if v_ok else BAD_COLOR)
	angle_label.add_theme_color_override("font_color", OK_COLOR if a_ok else BAD_COLOR)


func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = text != ""
