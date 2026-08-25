extends Control

@onready var status_label: Label = %StatusLabel
@onready var quest_panel: PanelContainer = %QuestPanel
@onready var quest_text: RichTextLabel = %QuestText


func _ready() -> void:
	if not GameState.has_active_game():
		get_tree().change_scene_to_file(AppConstants.MAIN_MENU_SCENE)
		return
	var state: Dictionary = GameState.current_state
	status_label.text = "%s • %s • %s\nCurrent location: %s\nLife path: %s" % [
		str(state["clock"]["weekday"]).capitalize(),
		str(state["clock"]["block"]).replace("_", " ").capitalize(),
		"August %d" % state["clock"]["day"],
		str(state["world_state"]["current_location"]).replace("_", " "),
		str(state["player"]["life_path"]).replace("_", " ").capitalize(),
	]
	_refresh_quests()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("phone") or event.is_action_pressed("quest_tracker"):
		quest_panel.visible = not quest_panel.visible
		get_viewport().set_input_as_handled()


func _refresh_quests() -> void:
	var lines: PackedStringArray = ["[font_size=28][b]QUEST TRACKER[/b][/font_size]"]
	for quest: Variant in QuestService.get_active_quests():
		if quest is Dictionary:
			lines.append("[b]%s[/b]\n%s" % [quest.get("title", quest.get("id", "Quest")), quest.get("summary", "")])
	quest_text.text = "\n\n".join(lines)


func _on_open_tracker_pressed() -> void:
	quest_panel.visible = not quest_panel.visible


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file(AppConstants.MAIN_MENU_SCENE)
