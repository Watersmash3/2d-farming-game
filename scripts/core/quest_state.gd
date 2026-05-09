extends Node

signal quest_added(quest_name: String, description: String)
signal quest_removed(quest_name: String)
signal quest_completed(quest_name: String)

# Stores all active quests
var active_quests: Dictionary = {}
# Stores completed quest names so they don't repeat
var completed_quests: Array[String] = []

func start_quest(quest_name: String, description: String) -> void:
	if is_complete(quest_name) or active_quests.has(quest_name):
		return
	active_quests[quest_name] = description
	quest_added.emit(quest_name, description)

func complete_quest(quest_name: String) -> void:
	if not active_quests.has(quest_name):
		return
	active_quests.erase(quest_name)
	completed_quests.append(quest_name)
	quest_completed.emit(quest_name)
	quest_removed.emit(quest_name)

func is_active(quest_name: String) -> bool:
	return active_quests.has(quest_name)

func is_complete(quest_name: String) -> bool:
	return completed_quests.has(quest_name)
