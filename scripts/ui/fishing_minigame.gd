extends CanvasLayer
class_name FishingMinigame

signal fishing_finished(success: bool)

const CAST_DELAY := 0.65
const ATTEMPT_TIME := 2.5
const TARGET_WIDTH := 0.25
const BASE_MARKER_SPEED := 0.55
const TARGET_SPEED_BOOST := 1.05
const TARGET_SPEED_RANGE := 0.42
const END_SLOW_ZONE := 0.16
const PANEL_BOTTOM_MARGIN := 120.0

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = $Root/Panel
@onready var _status: Label = $Root/Panel/Margin/VBox/Status
@onready var _bar: ColorRect = $Root/Panel/Margin/VBox/Bar
@onready var _target: ColorRect = $Root/Panel/Margin/VBox/Bar/Target
@onready var _marker: ColorRect = $Root/Panel/Margin/VBox/Bar/Marker

var _active := false
var _ready_for_input := false
var _cast_timer := 0.0
var _attempt_timer := 0.0
var _marker_pos := 0.0
var _marker_dir := 1.0
var _target_start := 0.0


func _ready() -> void:
	layer = 64
	visible = false
	_root.visible = false
	_root.gui_input.connect(_on_root_gui_input)
	_apply_theme()
	_position_panel()


func start() -> void:
	_active = true
	_ready_for_input = false
	_cast_timer = CAST_DELAY
	_attempt_timer = ATTEMPT_TIME
	_marker_pos = 0.0
	_marker_dir = 1.0
	_target_start = randf_range(0.1, 1.0 - TARGET_WIDTH - 0.1)
	_status.text = "Casting..."
	visible = true
	_root.visible = true
	_position_panel()
	_layout_bar()
	get_viewport().set_input_as_handled()


func is_active() -> bool:
	return _active


func _process(delta: float) -> void:
	if not _active:
		return

	if not _ready_for_input:
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			_ready_for_input = true
			_status.text = "Hook!"
		_layout_bar()
		return

	_attempt_timer -= delta
	if _attempt_timer <= 0.0:
		_finish(false)
		return

	_marker_pos += _current_marker_speed() * _marker_dir * delta
	if _marker_pos >= 1.0:
		_marker_pos = 1.0
		_marker_dir = -1.0
	elif _marker_pos <= 0.0:
		_marker_pos = 0.0
		_marker_dir = 1.0
	_layout_bar()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event.is_action_pressed("cancel_placement"):
		_finish(false)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_resolve()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		_try_resolve()
		get_viewport().set_input_as_handled()


func _on_root_gui_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_resolve()
		get_viewport().set_input_as_handled()


func _try_resolve() -> void:
	if not _ready_for_input:
		return
	var success := _marker_pos >= _target_start and _marker_pos <= _target_start + TARGET_WIDTH
	_finish(success)


func _finish(success: bool) -> void:
	if not _active:
		return
	_active = false
	_ready_for_input = false
	visible = false
	_root.visible = false
	fishing_finished.emit(success)


func _layout_bar() -> void:
	if _bar == null:
		return
	var bar_size := _bar.size
	if bar_size.x <= 0.0:
		return
	_target.size = Vector2(bar_size.x * TARGET_WIDTH, bar_size.y)
	_target.position = Vector2(bar_size.x * _target_start, 0.0)
	_marker.size = Vector2(4.0, bar_size.y + 6.0)
	_marker.position = Vector2((bar_size.x - _marker.size.x) * _marker_pos, -3.0)


func _current_marker_speed() -> float:
	var target_center: float = _target_start + TARGET_WIDTH * 0.5
	var target_distance: float = abs(_marker_pos - target_center)
	var target_closeness: float = 1.0 - clampf(target_distance / TARGET_SPEED_RANGE, 0.0, 1.0)
	var log_boost: float = log(1.0 + target_closeness * 7.0) / log(8.0)

	var end_distance: float = minf(_marker_pos, 1.0 - _marker_pos)
	var end_slow: float = clampf(end_distance / END_SLOW_ZONE, 0.0, 1.0)
	var end_factor: float = lerpf(0.35, 1.0, end_slow)

	return (BASE_MARKER_SPEED + TARGET_SPEED_BOOST * log_boost) * end_factor


func _position_panel() -> void:
	if _panel == null:
		return
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -150.0
	_panel.offset_right = 150.0
	_panel.offset_top = -PANEL_BOTTOM_MARGIN - 116.0
	_panel.offset_bottom = -PANEL_BOTTOM_MARGIN


func _apply_theme() -> void:
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#241b14", 0.96)
	panel_style.border_color = Color("#e7c56a")
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	_panel.add_theme_stylebox_override("panel", panel_style)

	_status.add_theme_color_override("font_color", Color("#f3dfb2"))
	_bar.color = Color("#14100c", 0.96)
	_target.color = Color("#68c66f", 0.9)
	_marker.color = Color("#fff1c5")
