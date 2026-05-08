#Use of ClaudeAI to handle some of the string formatting and logic
extends Control

@onready var header: NinePatchRect = $QuestLogHeader
@onready var chevron: Button = $Button
@onready var body: NinePatchRect = $QuestLogBody
@onready var quest_text: RichTextLabel = $QuestText

var expanded = false
var quests: Dictionary = {}

func _ready():
	await get_tree().process_frame
	chevron.pivot_offset = chevron.size / 2
	body.visible = false
	quest_text.visible = false
	chevron.rotation_degrees = 180

func _on_button_pressed():
	expanded = !expanded
	body.visible = expanded
	quest_text.visible = expanded
	chevron.rotation_degrees = 0 if expanded else 180

func add_quest(quest_name: String, description: String):
	quests[quest_name] = description
	_rebuild()

func remove_quest(quest_name: String):
	quests.erase(quest_name)
	_rebuild()

func _rebuild():
	quest_text.clear()
	for q in quests:
		quest_text.append_text("• [b]%s[/b]: %s\n" % [q, quests[q]])
	await get_tree().process_frame 
	#add 32 for padding purposes
	var new_height = quest_text.get_content_height() + 32
	body.custom_minimum_size.y = new_height
	body.size.y = new_height
