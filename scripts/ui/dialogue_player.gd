#File based on this youtube video: https://www.youtube.com/watch?v=LMSbPkNgnWA 
#As well as ClaudeAI to help with inventory system problems. 
extends Control

signal dialogue_finished
@export var dialogue_files: Array[String] = []
@export var required_item = ""
@export var required_amount = 0
@export var reward_item = ""
@export var reward_amount = 0
@export var quest_name: String = ""
@export var quest_descr: String = ""


var dialogue = []
var current_dialogue_id = 0
var d_active = false

enum QuestState { 
	NOT_STARTED, 
	IN_PROGRESS,
	COMPLETE 
}
var quest_state = QuestState.NOT_STARTED

func _ready():
	$NinePatchRect.visible = false
	$NinePatchRect2.visible = false
	
func start():
	if d_active:
		return
	d_active = true
	$NinePatchRect.visible = true
	dialogue = load_dialogue()
	current_dialogue_id = -1
	next_script()
	
func load_dialogue():
	var file_path = _pick_dialogue_file()
	if file_path == "":
		return []
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = JSON.parse_string(file.get_as_text())
	return content

func _pick_dialogue_file() -> String:
	if dialogue_files.size() < 3:
		push_error("Need 3 dialogue files on " + get_parent().name)
		return ""
	match quest_state:
		QuestState.NOT_STARTED:
			return dialogue_files[0]
		QuestState.IN_PROGRESS:
			if _player_has_items():
				return dialogue_files[2]
			else:
				return dialogue_files[1]
		QuestState.COMPLETE:
			return dialogue_files[3]
	return dialogue_files[1]
		
func _player_has_items() -> bool:
	return InventoryState.has_item(required_item, required_amount)

func _handle_quest_progression():
	var quest_log = get_tree().get_first_node_in_group("quest_log")
	match quest_state:
		QuestState.NOT_STARTED:
			quest_state = QuestState.IN_PROGRESS
			if quest_log:
				quest_log.add_quest(quest_name, quest_descr)
		QuestState.IN_PROGRESS:
			if _player_has_items():
				_give_reward()
				quest_state = QuestState.COMPLETE
				if quest_log:
					quest_log.remove_quest(quest_name)
		QuestState.COMPLETE:
			pass

func _give_reward():
	InventoryState.remove_item(required_item, required_amount)
	InventoryState.add_item(reward_item, reward_amount)
	
func _input(event):
	if !d_active:
		return
	if event.is_action_pressed("progress_chat"):
		next_script()

func next_script():
	current_dialogue_id += 1
	if current_dialogue_id >= len(dialogue):
		d_active = false
		$NinePatchRect.visible = false
		_handle_quest_progression()
		emit_signal("dialogue_finished")
		return 
	$NinePatchRect/Name.text = dialogue[current_dialogue_id]['name']
	$NinePatchRect/Text.text = dialogue[current_dialogue_id]['text']
