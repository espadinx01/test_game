extends StaticBody2D
class_name Terrain


const STEP := 40.0        # horizontal distance between terrain points
const MIN_Y := 650.0
const MAX_Y := 950.0
const BOTTOM_Y := 1500.0  # how far the solid ground extends down

var points := PackedVector2Array()
var pads: Array[Dictionary] = []   # {x_start, x_end, y, multiplier}

@onready var collision: CollisionPolygon2D = $CollisionPolygon2D


func generate(world_width: float, roughness: float, pad_defs: Array[Dictionary]) -> void:
	points.clear()
	pads.clear()

	# 1) Random-walk the ground height.
	var count := int(world_width / STEP) + 1
	var y := 800.0
	for i in count:
		y = clampf(y + randf_range(-roughness, roughness), MIN_Y, MAX_Y)
		points.append(Vector2(i * STEP, y))

	# 2) Flatten one pad per "slot" so pads are spread over the map.
	var defs := pad_defs.duplicate()
	defs.shuffle()
	var slot := int(float(count) / defs.size())
	for j in defs.size():
		var segs: int = defs[j].segments
		var start := j * slot + randi_range(2, slot - segs - 2)
		var pad_y := points[start].y
		for k in range(start, start + segs + 1):
			points[k] = Vector2(points[k].x, pad_y)
		pads.append({
			"x_start": points[start].x,
			"x_end": points[start + segs].x,
			"y": pad_y,
			"multiplier": defs[j].multiplier,
		})

	collision.polygon = _build_polygon()
	queue_redraw()


func _build_polygon() -> PackedVector2Array:
	var poly := points.duplicate()
	poly.append(Vector2(points[points.size() - 1].x, BOTTOM_Y))
	poly.append(Vector2(0.0, BOTTOM_Y))
	return poly


# Ground height at any x (linear interpolation between points).
func get_height_at(x: float) -> float:
	var i := clampi(int(x / STEP), 0, points.size() - 2)
	var a := points[i]
	var b := points[i + 1]
	return lerpf(a.y, b.y, clampf((x - a.x) / STEP, 0.0, 1.0))


# Returns the pad that fully contains [x_left, x_right], or {} if none.
func get_pad_at(x_left: float, x_right: float) -> Dictionary:
	for p in pads:
		if x_left >= p.x_start and x_right <= p.x_end:
			return p
	return {}


func _draw() -> void:
	if points.is_empty():
		return
	draw_colored_polygon(_build_polygon(), Color("23232d"))
	draw_polyline(points, Color("c9c9d6"), 2.0)
	for p in pads:
		draw_line(Vector2(p.x_start, p.y), Vector2(p.x_end, p.y), Color("5dff8a"), 5.0)
		draw_string(ThemeDB.fallback_font, Vector2(p.x_start, p.y + 30.0), "x%d" % p.multiplier,
				HORIZONTAL_ALIGNMENT_CENTER, p.x_end - p.x_start, 22, Color("5dff8a"))
