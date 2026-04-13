extends Node
class_name TimeService

signal day_advanced(new_day: int, old_day: int)
signal hour_advanced(new_hour: int, old_hour: int)

@export var tick_duration_seconds: float = 0.25
## When true the clock starts paused; set_paused(false) or the world controller will resume it.
@export var start_paused: bool = true

var time_tick: TimeTick
var _tick_seconds: float = 0.25  # runtime-adjustable copy
var _is_paused: bool = false

func _ready() -> void:
	_tick_seconds = tick_duration_seconds
	_is_paused = start_paused
	_init_time_tick(_tick_seconds)

func _init_time_tick(tick_secs: float) -> void:
	if time_tick:
		time_tick.shutdown()
	time_tick = TimeTick.new()
	time_tick.initialize(tick_secs)

	time_tick.register_time_unit("hour", "tick", 1, 24, 0)
	time_tick.register_time_unit("day", "hour", 24, -1, 1)

	time_tick.time_unit_changed.connect(_on_time_unit_changed)

	time_tick.set_time_unit("day", 1)
	time_tick.set_time_unit("hour", 6)

	if _is_paused:
		time_tick.pause()

func _exit_tree() -> void:
	if time_tick:
		time_tick.shutdown()

func _on_time_unit_changed(unit_name: String, new_value: int, old_value: int) -> void:
	if unit_name == "day":
		day_advanced.emit(new_value, old_value)
	elif unit_name == "hour":
		hour_advanced.emit(new_value, old_value)

func set_paused(paused: bool) -> void:
	if not time_tick: return
	_is_paused = paused
	if paused:
		time_tick.pause()
	else:
		time_tick.resume()

func get_current_hour() -> int:
	if not time_tick: return 0
	return time_tick.get_time_unit("hour")

func get_current_day() -> int:
	if not time_tick: return 1
	return time_tick.get_time_unit("day")

## Change the tick speed at runtime (seconds per tick). Preserves current day/hour.
func set_tick_speed(seconds_per_tick: float) -> void:
	if not time_tick: return
	var cur_day  := get_current_day()
	var cur_hour := get_current_hour()
	_tick_seconds = seconds_per_tick

	_init_time_tick(_tick_seconds)
	time_tick.set_time_unit("day", cur_day)
	time_tick.set_time_unit("hour", cur_hour)
	if _is_paused:
		time_tick.pause()

func advance_day() -> void:
	if not time_tick: return
	var old_day := get_current_day()
	time_tick.set_time_unit("hour", 6)
	time_tick.set_time_unit("day", old_day + 1)
