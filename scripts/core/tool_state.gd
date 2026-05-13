extends Node

signal tool_changed(tool_id: int)

const TOOL_HOE := 1
const TOOL_WATER := 2
const TOOL_PLANT := 3
const TOOL_HARVEST := 4

const TOOL_LABELS := {
	TOOL_HOE: "Hoe",
	TOOL_WATER: "Water",
	TOOL_PLANT: "Plant",
	TOOL_HARVEST: "Harvest",
}

var selected_tool: int = TOOL_HOE


func set_selected_tool(tool_id: int) -> void:
	if not TOOL_LABELS.has(tool_id):
		return
	if selected_tool == tool_id:
		return
	selected_tool = tool_id
	tool_changed.emit(selected_tool)


func get_selected_tool_label() -> String:
	return str(TOOL_LABELS.get(selected_tool, "None"))
