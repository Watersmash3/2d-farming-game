extends Node
class_name TimeService

signal day_advanced(new_day: int, old_day: int)

@export var tick_duration_seconds: float  = 0.25
@export var start_paused: bool = true

var time_tick: TimeTick

func _ready() -> void:
	time_tick = TimeTick.new()
	time_tick.initialize(tick_duration_seconds)
	
	time_tick.register_time_unit("hour", "tick", 1, 24, 0)
	time_tick.register_time_unit("day", "hour", 24, -1, 1)
	
	time_tick.time_unit_changed.connect(_on_time_unit_changed)
	
	time_tick.set_time_unit("day", 1)
	time_tick.set_time_unit("hour", 6)
	
	if start_paused:
		time_tick.pause()

func _exit_tree() -> void:
	if time_tick:
		time_tick.shutdown()

func _on_time_unit_changed(unit_name: String, new_value: int, old_value: int) -> void:
	if unit_name == "day":
		day_advanced.emit(new_value, old_value)

func set_paused(paused: bool) -> void:
	if paused:
		time_tick.pause()
	else:
		time_tick.resume()

func advance_day() -> void:
	var old_day := time_tick.get_time_unit("day")
	time_tick.set_time_unit("hour", 0)
	time_tick.set_time_unit("day", old_day + 1)
1
