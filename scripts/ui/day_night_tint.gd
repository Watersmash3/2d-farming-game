extends CanvasModulate

## Smoothly shifts the world tint based on in-game hour.
## Attach this script to a CanvasModulate node in World.tscn.

const HOUR_COLORS: Dictionary = {
	0:  Color(0.12, 0.12, 0.22),  # midnight — deep night
	4:  Color(0.18, 0.18, 0.30),  # pre-dawn
	5:  Color(0.50, 0.45, 0.55),  # early dawn glow
	6:  Color(0.85, 0.75, 0.60),  # sunrise — warm gold
	7:  Color(0.95, 0.90, 0.80),  # morning
	8:  Color(1.00, 1.00, 1.00),  # full daylight
	17: Color(1.00, 1.00, 1.00),  # still daylight at 5pm
	18: Color(0.95, 0.80, 0.55),  # golden hour
	19: Color(0.80, 0.55, 0.35),  # sunset orange
	20: Color(0.55, 0.45, 0.60),  # dusk purple
	21: Color(0.30, 0.28, 0.45),  # evening
	22: Color(0.18, 0.18, 0.30),  # night
	23: Color(0.12, 0.12, 0.22),  # late night
}

const TWEEN_DURATION: float = 1.5


func _ready() -> void:
	TimeSystem.hour_advanced.connect(_on_hour_advanced)
	color = _color_for_hour(TimeSystem.get_current_hour())


func _on_hour_advanced(new_hour: int, _old_hour: int) -> void:
	var target := _color_for_hour(new_hour)
	var tw := create_tween()
	tw.tween_property(self, "color", target, TWEEN_DURATION)


## Linearly interpolates between the two nearest hour keyframes.
func _color_for_hour(hour: int) -> Color:
	var keys: Array = HOUR_COLORS.keys()
	keys.sort()

	# Find the surrounding keyframes
	var prev_key: int = keys[0]
	var next_key: int = keys[keys.size() - 1]
	for k: int in keys:
		if k <= hour:
			prev_key = k
		elif k > hour:
			next_key = k
			break

	if prev_key == next_key:
		return HOUR_COLORS[prev_key] as Color

	var span: float = float(next_key - prev_key)
	var t: float = float(hour - prev_key) / span
	return (HOUR_COLORS[prev_key] as Color).lerp(HOUR_COLORS[next_key] as Color, t)
