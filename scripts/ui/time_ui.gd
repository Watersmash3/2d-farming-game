extends CanvasLayer

## Displays the current in-game day and hour as a compact HUD.
## Add this scene to World.tscn to activate it.

@onready var day_label: Label = $Panel/VBox/DayLabel
@onready var hour_bar: ProgressBar = $Panel/VBox/HourBar
@onready var hour_label: Label = $Panel/VBox/HourLabel


func _ready() -> void:
	TimeSystem.day_advanced.connect(_on_day_advanced)
	TimeSystem.hour_advanced.connect(_on_hour_advanced)
	_refresh()


func _refresh() -> void:
	var day  := TimeSystem.get_current_day()
	var hour := TimeSystem.get_current_hour()
	day_label.text  = "Day %d" % day
	hour_bar.value  = float(hour)
	hour_label.text = _hour_to_label(hour)


func _on_day_advanced(_new_day: int, _old_day: int) -> void:
	_refresh()


func _on_hour_advanced(_new_hour: int, _old_hour: int) -> void:
	_refresh()


func _hour_to_label(h: int) -> String:
	var period := "AM" if h < 12 else "PM"
	var display := h % 12
	if display == 0:
		display = 12
	return "%d:00 %s" % [display, period]
