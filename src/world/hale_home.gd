extends Control

const HouseholdScheduleEngineScript: GDScript = preload("res://src/world/household_schedule_engine.gd")
const HOUSEHOLD_CHARACTER_IDS: PackedStringArray = ["elena_reyes_hale", "daniel_hale", "lily_hale"]
const MONTH_NAMES: PackedStringArray = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
]

const ROOMS: Dictionary = {
	"player_bedroom": {
		"name": "Your Bedroom",
		"description": "Morning light slips through the blinds. Your bed, wardrobe, desk, and phone make this the quiet center of your life at home.",
		"color": Color("243b4b"),
	},
	"upstairs_hall": {
		"name": "Upstairs Hall",
		"description": "Family photographs line the hall between the bedrooms and bathroom. Closed doors deserve a knock.",
		"color": Color("34404a"),
	},
	"family_bathroom": {
		"name": "Family Bathroom",
		"description": "A shared bathroom with a shower, deep tub, mirror, and the everyday supplies needed to stay clean and presentable.",
		"color": Color("23505a"),
	},
	"lily_bedroom": {
		"name": "Lily's Bedroom",
		"description": "Lily's room is private. You need her permission before entering.",
		"color": Color("4a3547"),
		"private": true,
	},
	"living_room": {
		"name": "Living Room",
		"description": "A comfortable shared room for television, reading, family conversations, and the occasional guest.",
		"color": Color("344b43"),
	},
	"dining_room": {
		"name": "Dining Room",
		"description": "The family table sits beneath a warm pendant light. Meals here often become conversations about everyone's day.",
		"color": Color("4d4534"),
	},
	"kitchen": {
		"name": "Kitchen",
		"description": "The kitchen is stocked with basic groceries, snacks, and enough equipment to prepare a simple meal.",
		"color": Color("3b4c39"),
	},
	"parents_bedroom": {
		"name": "Parents' Bedroom",
		"description": "Your parents' room is private. You should knock and wait for permission.",
		"color": Color("493737"),
		"private": true,
	},
	"backyard": {
		"name": "Backyard",
		"description": "A fenced green space with room to exercise, relax in the coastal air, or host a small gathering.",
		"color": Color("294b39"),
	},
	"laundry_room": {
		"name": "Laundry Room",
		"description": "The washer, dryer, and folding counter keep the household wardrobe clean and ready for the weather.",
		"color": Color("334953"),
	},
	"garage": {
		"name": "Garage",
		"description": "Storage shelves and Daniel's tools surround the family car. Using it depends on the household agreement.",
		"color": Color("41464a"),
	},
	"front_yard": {
		"name": "Front Yard",
		"description": "The front walk opens toward Alder Heights and the rest of Port Alder. Choose a destination on your phone before leaving.",
		"color": Color("344e3a"),
	},
}

const ROOM_ORDER: PackedStringArray = [
	"player_bedroom", "upstairs_hall", "family_bathroom", "lily_bedroom",
	"living_room", "dining_room", "kitchen", "parents_bedroom",
	"backyard", "laundry_room", "garage", "front_yard",
]
const NAVIGABLE_ROOM_ORDER: PackedStringArray = [
	"player_bedroom", "upstairs_hall", "lily_bedroom", "family_bathroom", "parents_bedroom", "living_room",
	"dining_room", "kitchen", "backyard", "laundry_room", "garage", "front_yard",
]
const PRIVATE_DOOR_RULES: Dictionary = {
	"lily_bedroom": {"always_locked_blocks": ["early_morning", "night"], "chance_percent": 45, "salt": 17},
	"parents_bedroom": {"always_locked_blocks": ["night"], "chance_percent": 35, "salt": 43},
}
const BATHROOM_BUSY_CHANCES: Dictionary = {
	"early_morning": 75,
	"evening": 30,
	"late_evening": 60,
	"night": 20,
}
const BATHROOM_OCCUPANT_IDS: PackedStringArray = ["elena_reyes_hale", "daniel_hale", "lily_hale"]
const BATHROOM_SLOT_MINUTES: int = 20
const ACTIVITY_BLOCKS: PackedStringArray = [
	"early_morning", "morning", "lunch", "afternoon", "evening", "late_evening", "night",
]

const INTERACTIONS: Array = [
	{"room": "player_bedroom", "label": "Bed", "actions": ["nap", "sleep"]},
	{"room": "player_bedroom", "label": "Open Wardrobe", "special": "wardrobe"},
	{"room": "player_bedroom", "label": "Use Phone", "special": "phone"},
	{"room": "family_bathroom", "label": "Shower or Bath", "actions": ["shower", "bath"]},
	{"room": "family_bathroom", "label": "Bathroom Sink", "actions": ["brush_teeth", "groom"]},
	{"room": "upstairs_hall", "label": "Knock on Lily's Door", "special": "lily_door"},
	{"room": "upstairs_hall", "label": "Knock on Parents' Door", "special": "parents_door"},
	{"room": "lily_bedroom", "label": "Knock on Lily's Door", "special": "lily_door"},
	{"room": "parents_bedroom", "label": "Knock on Parents' Door", "special": "parents_door"},
	{"room": "living_room", "label": "Relax on the Sofa", "special": "sofa"},
	{"room": "dining_room", "label": "Have a Snack", "actions": ["eat_snack"]},
	{"room": "kitchen", "label": "Kitchen Counter", "actions": ["drink_water", "eat_snack", "cook_basic_meal"]},
	{"room": "laundry_room", "label": "Do Laundry", "actions": ["do_laundry"]},
	{"room": "garage", "label": "Check the Family Car", "special": "family_car"},
	{"room": "backyard", "label": "Spend Time Outside", "special": "backyard"},
	{"room": "front_yard", "label": "Open City Map", "special": "leave_home"},
]

@onready var backdrop: ColorRect = %Backdrop
@onready var background_image: TextureRect = %BackgroundImage
@onready var room_label: Label = %RoomLabel
@onready var scene_title: Label = %SceneTitle
@onready var scene_description: Label = %SceneDescription
@onready var portrait_stage: HBoxContainer = %PortraitStage
@onready var character_text: RichTextLabel = %CharacterText
@onready var clock_label: Label = %ClockLabel
@onready var needs_label: Label = %NeedsLabel
@onready var status_label: Label = %StatusLabel
@onready var room_buttons: VBoxContainer = %RoomButtons
@onready var action_title: Label = %ActionTitle
@onready var action_buttons: VBoxContainer = %ActionButtons
@onready var previous_room_arrow: Button = %PrevRoomArrow
@onready var outside_arrow: Button = %OutsideArrow
@onready var next_room_arrow: Button = %NextRoomArrow
@onready var wardrobe_panel: PanelContainer = %WardrobePanel
@onready var wardrobe_list: VBoxContainer = %WardrobeList
@onready var outfit_text: RichTextLabel = %OutfitText
@onready var quest_panel: PanelContainer = %QuestPanel
@onready var quest_text: RichTextLabel = %QuestText
@onready var smartphone: Control = %Smartphone

var _current_room: String = "player_bedroom"
var _schedule_engine: RefCounted
var _npc_resolutions: Dictionary = {}
var _schedule_signature: String = ""


func _ready() -> void:
	if not GameState.has_active_game():
		get_tree().change_scene_to_file(AppConstants.MAIN_MENU_SCENE)
		return
	if not SettingsService.settings_changed.is_connected(_apply_accessibility_settings):
		SettingsService.settings_changed.connect(_apply_accessibility_settings)
	_schedule_engine = HouseholdScheduleEngineScript.new(ContentRegistry)
	smartphone.phone_opened.connect(_on_phone_opened)
	smartphone.phone_closed.connect(_on_phone_closed)
	smartphone.travel_completed.connect(_on_travel_completed)
	_restore_room()
	_sync_household_schedule(true)
	_render_room()
	_refresh_hud()
	_apply_accessibility_settings()


func _process(_delta: float) -> void:
	_sync_household_schedule()
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if smartphone.is_open():
		if event.is_action_pressed("cancel") or event.is_action_pressed("phone"):
			smartphone.close_phone()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("cancel") and (wardrobe_panel.visible or quest_panel.visible):
		_close_panels()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quest_tracker"):
		_toggle_quest_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("phone"):
		smartphone.open_phone()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("city_map"):
		smartphone.open_phone("city_map")
		get_viewport().set_input_as_handled()


func _restore_room() -> void:
	var location: String = str(GameState.current_state["world_state"].get("current_location", "hale_home.player_bedroom"))
	var room_id: String = location.trim_prefix("hale_home.") if location.begins_with("hale_home.") else "player_bedroom"
	_current_room = room_id if ROOMS.has(room_id) else "player_bedroom"
	_update_world_location(false)


func _select_room(room_id: String) -> void:
	if not ROOMS.has(room_id):
		return
	var changed: bool = room_id != _current_room
	_current_room = room_id
	_update_world_location(changed)
	_render_room()
	if bool(ROOMS[room_id].get("private", false)):
		var doorway_name: String = "Lily's doorway" if room_id == "lily_bedroom" else "your parents' doorway"
		status_label.text = "You stop at %s. Knock before entering the private room." % doorway_name
	elif room_id == "family_bathroom":
		var bathroom_state: Dictionary = _bathroom_door_state()
		if str(bathroom_state.get("status", "available")) == "occupied_locked":
			status_label.text = "The bathroom door is locked because someone is using it. You can knock or wait."
		elif str(bathroom_state.get("status", "available")) == "locked":
			status_label.text = "The bathroom door is locked. You can knock or wait."


func _set_current_room(room_id: String) -> void:
	_select_room(room_id)


func _update_world_location(record_event: bool) -> void:
	var location_path: String = "hale_home.%s" % _current_room
	if str(GameState.current_state["world_state"].get("current_location", "")) != location_path:
		var next_state: Dictionary = GameState.current_state.duplicate(true)
		next_state["world_state"]["current_location"] = location_path
		GameState.replace_state(next_state)
	if record_event:
		QuestService.record_event("location_entered", {"location": location_path}, "home.room_selected")


func _render_room() -> void:
	if not is_node_ready() or not ROOMS.has(_current_room):
		return
	var room: Dictionary = ROOMS[_current_room]
	backdrop.color = room.get("color", Color("243b4b"))
	VNAssetService.apply_background(background_image, "hale_home", _current_room, str(GameState.current_state["clock"].get("block", "")))
	room_label.text = str(room["name"])
	scene_title.text = str(room["name"]).to_upper()
	scene_description.text = str(room["description"])
	_rebuild_room_buttons()
	_refresh_directional_navigation()
	_rebuild_character_stage()
	_rebuild_room_actions()


func _rebuild_room_buttons() -> void:
	_clear_container(room_buttons)
	for room_id: String in ROOM_ORDER:
		var room: Dictionary = ROOMS[room_id]
		var button: Button = Button.new()
		var current_prefix: String = "● " if room_id == _current_room else ""
		var private_suffix: String = ""
		if bool(room.get("private", false)):
			private_suffix = "  • Locked" if _private_door_locked(room_id) else "  • Knock First"
		elif room_id == "family_bathroom":
			var bathroom_status: String = str(_bathroom_door_state().get("status", "available"))
			if bathroom_status == "occupied_locked":
				private_suffix = "  • Occupied"
			elif bathroom_status == "locked":
				private_suffix = "  • Locked"
		button.text = "%s%s%s" % [current_prefix, room["name"], private_suffix]
		button.custom_minimum_size = Vector2(0, 43)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_room.bind(room_id))
		room_buttons.add_child(button)


func _refresh_directional_navigation() -> void:
	var current_index: int = NAVIGABLE_ROOM_ORDER.find(_current_room)
	var previous_id: String = NAVIGABLE_ROOM_ORDER[current_index - 1] if current_index > 0 else ""
	var next_id: String = NAVIGABLE_ROOM_ORDER[current_index + 1] if current_index >= 0 and current_index + 1 < NAVIGABLE_ROOM_ORDER.size() else ""
	previous_room_arrow.disabled = previous_id.is_empty()
	previous_room_arrow.text = "◀ %s" % (ROOMS[previous_id]["name"] if not previous_id.is_empty() else "No Previous Room")
	next_room_arrow.disabled = next_id.is_empty()
	next_room_arrow.text = "%s ▶" % (ROOMS[next_id]["name"] if not next_id.is_empty() else "No Next Room")
	outside_arrow.text = "▲ Leave Home / City Map" if _current_room == "front_yard" else "▲ Outside • Front Yard"
	SettingsService.apply_accessibility(previous_room_arrow)
	SettingsService.apply_accessibility(outside_arrow)
	SettingsService.apply_accessibility(next_room_arrow)


func _on_previous_room_pressed() -> void:
	var current_index: int = NAVIGABLE_ROOM_ORDER.find(_current_room)
	if current_index > 0:
		_select_room(NAVIGABLE_ROOM_ORDER[current_index - 1])


func _on_next_room_pressed() -> void:
	var current_index: int = NAVIGABLE_ROOM_ORDER.find(_current_room)
	if current_index >= 0 and current_index + 1 < NAVIGABLE_ROOM_ORDER.size():
		_select_room(NAVIGABLE_ROOM_ORDER[current_index + 1])


func _on_outside_pressed() -> void:
	if _current_room != "front_yard":
		_select_room("front_yard")
		status_label.text = "You head outside to the front yard. Use the up arrow again to open Port Alder."
		return
	TravelService.start_transportation_tutorial("home.directional_exit")
	smartphone.open_phone("city_map")
	status_label.text = "Choose an unlocked Port Alder destination and confirm a route."


func _rebuild_character_stage() -> void:
	_clear_container(portrait_stage)
	if _current_room == "family_bathroom":
		var bathroom_status: String = str(_bathroom_door_state().get("status", "available"))
		if bathroom_status != "available":
			var door_message: String = "Someone is using the bathroom, and the door is locked for privacy." if bathroom_status == "occupied_locked" else "The bathroom door is locked. No one answers from inside."
			character_text.text = "[center][font_size=25][color=#b8c7c7]%s You remain in the hallway outside.[/color][/font_size][/center]" % door_message
			portrait_stage.visible = false
			character_text.visible = true
			return
	if bool(ROOMS[_current_room].get("private", false)):
		var door_state: String = "locked" if _private_door_locked(_current_room) else "closed"
		character_text.text = "[center][font_size=25][color=#b8c7c7]The private bedroom door is %s. You are at the doorway and should knock before entering.[/color][/font_size][/center]" % door_state
		portrait_stage.visible = false
		character_text.visible = true
		return
	var lines: PackedStringArray = []
	for character_id_value: Variant in _npc_resolutions:
		var character_id: String = str(character_id_value)
		var resolution: Dictionary = _npc_resolutions[character_id]
		if not bool(resolution.get("present", false)) or str(resolution.get("room", "")) != _current_room:
			continue
		var character: Variant = ContentRegistry.get_character(character_id)
		var display_name: String = str(character.get("display_name", character_id)) if character is Dictionary else character_id
		lines.append("[center][font_size=34][b]%s[/b][/font_size]\n[color=#e9a86c]%s[/color][/center]" % [display_name, resolution.get("activity_label", "At home")])
		_add_portrait_card(portrait_stage, character_id, display_name, str(resolution.get("activity_label", "At home")))
	character_text.text = "\n\n".join(lines) if not lines.is_empty() else "[center][font_size=25][color=#b8c7c7]No one else is in this room right now.[/color][/font_size][/center]"
	portrait_stage.visible = not lines.is_empty()
	character_text.visible = lines.is_empty()


func _add_portrait_card(container: HBoxContainer, character_id: String, display_name: String, subtitle: String) -> void:
	var card: VBoxContainer = VBoxContainer.new()
	card.custom_minimum_size = Vector2(170, 0)
	card.add_theme_constant_override("separation", 4)
	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(170, 250)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	VNAssetService.apply_portrait(portrait, character_id)
	card.add_child(portrait)
	var name_label: Label = Label.new()
	name_label.text = "%s\n%s" % [display_name, subtitle]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("eef6f5"))
	card.add_child(name_label)
	container.add_child(card)


func _rebuild_room_actions() -> void:
	_clear_container(action_buttons)
	action_title.text = "CHOICES • %s" % ROOMS[_current_room]["name"]
	if _current_room == "family_bathroom":
		var bathroom_status: String = str(_bathroom_door_state().get("status", "available"))
		if bathroom_status != "available":
			var knock_label: String = "Knock on the Occupied Bathroom Door" if bathroom_status == "occupied_locked" else "Knock on the Locked Bathroom Door"
			_add_choice_button(knock_label, _handle_special.bind("bathroom_door"))
			_add_choice_button("Wait 20 Minutes", _wait_for_bathroom)
			SettingsService.apply_accessibility(action_buttons)
			return
	if bool(ROOMS[_current_room].get("private", false)):
		var special: String = "lily_door" if _current_room == "lily_bedroom" else "parents_door"
		var label: String = "Knock on the Locked Door" if _private_door_locked(_current_room) else "Knock Before Entering"
		_add_choice_button(label, _handle_special.bind(special))
		SettingsService.apply_accessibility(action_buttons)
		return
	for interaction: Dictionary in INTERACTIONS:
		if str(interaction.get("room", "")) != _current_room:
			continue
		if interaction.has("actions"):
			for action_id_value: Variant in interaction["actions"]:
				_add_home_action_button(str(action_id_value))
		else:
			_add_choice_button(str(interaction["label"]), _handle_special.bind(str(interaction.get("special", ""))))
	for character_id_value: Variant in _npc_resolutions:
		var character_id: String = str(character_id_value)
		var resolution: Dictionary = _npc_resolutions[character_id]
		if bool(resolution.get("present", false)) and str(resolution.get("room", "")) == _current_room:
			_add_choice_button("Talk to %s" % _first_name(character_id), _open_npc_panel.bind(character_id))
	if action_buttons.get_child_count() == 0:
		_add_choice_button("There is nothing you need to do here right now.", Callable(), false)
	SettingsService.apply_accessibility(action_buttons)


func _add_home_action_button(action_id: String) -> void:
	var action: Variant = ContentRegistry.get_content("actions", action_id)
	if action is Dictionary:
		_add_choice_button("%s\n%s" % [action.get("name", action_id), action.get("description", "")], _on_action_selected.bind(action_id))


func _add_choice_button(label: String, callback: Callable, enabled: bool = true) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 56)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = not enabled
	if enabled:
		button.pressed.connect(callback)
	action_buttons.add_child(button)
	return button


func _on_action_selected(action_id: String) -> void:
	var result: Dictionary = HomeActionService.perform(action_id)
	if result.get("ok", false):
		status_label.text = "%s completed. Time and your condition were updated." % result["action"].get("name", action_id)
	else:
		status_label.text = str(result.get("errors", ["That action could not be completed."])[0])
	_sync_household_schedule(true)
	_render_room()
	_refresh_hud()


func _perform_home_action(action_id: String) -> void:
	_on_action_selected(action_id)


func _handle_special(special: String) -> void:
	match special:
		"wardrobe": _open_wardrobe()
		"phone": smartphone.open_phone()
		"lily_door":
			status_label.text = "Lily's door is locked. You knock, but no one answers." if _private_door_locked("lily_bedroom") else "You knock. Lily asks for privacy right now, so the unlocked door remains closed."
		"parents_door":
			status_label.text = "Your parents' door is locked. You knock, but no one answers." if _private_door_locked("parents_bedroom") else "You knock. The door is unlocked, but their room remains private until they invite you in."
		"bathroom_door":
			var bathroom_status: String = str(_bathroom_door_state().get("status", "available"))
			if bathroom_status == "occupied_locked":
				status_label.text = "You knock. Someone answers that they will be out when they are finished."
			elif bathroom_status == "locked":
				status_label.text = "You knock on the locked bathroom door, but no one answers."
			else:
				status_label.text = "The bathroom is available now."
		"sofa": status_label.text = "You settle near the sofa. This is a natural place for family conversations and quiet downtime."
		"family_car":
			var permission: String = str(GameState.current_state["player"]["transportation"]["family_car_permission"])
			if permission == "regular_shared_access":
				status_label.text = "The family car is available under your regular shared-access agreement."
			elif permission in ["", "none", "denied"]:
				status_label.text = "You do not currently have permission to use the family car."
			else:
				var next_state: Dictionary = GameState.current_state.duplicate(true)
				next_state["world_state"]["world_flags"]["family_car_permission_date"] = "Y%d-%02d-%02d" % [next_state["clock"]["year"], next_state["clock"]["month"], next_state["clock"]["day"]]
				GameState.replace_state(next_state)
				status_label.text = "Permission is granted for today. Return the car with fuel and report any damage."
		"backyard": status_label.text = "The backyard can host exercise, relaxation, and small gatherings. More activities can unlock here later."
		"leave_home":
			TravelService.start_transportation_tutorial("home.front_gate")
			smartphone.open_phone("city_map")
			status_label.text = "Choose an unlocked Port Alder destination and confirm a route."


func _wait_for_bathroom() -> void:
	var result: Dictionary = TimeService.advance_minutes(BATHROOM_SLOT_MINUTES, "home.wait_for_bathroom")
	_sync_household_schedule(true)
	_render_room()
	if not result.get("ok", false):
		status_label.text = str(result.get("errors", ["You could not wait right now."])[0])
	elif str(_bathroom_door_state().get("status", "available")) == "available":
		status_label.text = "After waiting twenty minutes, the bathroom is available."
	else:
		status_label.text = "Twenty minutes pass, but the bathroom door is still locked."
	_refresh_hud()


func _open_npc_panel(character_id: String) -> void:
	var character: Variant = ContentRegistry.get_character(character_id)
	if not character is Dictionary:
		return
	_clear_container(action_buttons)
	action_title.text = "%s • %s" % [character.get("display_name", character_id), _npc_resolutions.get(character_id, {}).get("activity_label", "At home")]
	for conversation: Dictionary in _available_conversations(character):
		_add_choice_button("Talk • %s" % conversation.get("title", str(conversation.get("id", "Conversation")).replace("_", " ").capitalize()), _on_conversation_selected.bind(str(conversation.get("id", ""))))
	var ambient_line: String = _ambient_line(character)
	if not ambient_line.is_empty():
		_add_choice_button("Chat for a few minutes", _on_ambient_chat_selected.bind(character_id, ambient_line))
	if action_buttons.get_child_count() == 0:
		_add_choice_button("%s has nothing new to discuss right now." % _first_name(character_id), Callable(), false)
	_add_choice_button("Back to room choices", _render_room)
	SettingsService.apply_accessibility(action_buttons)


func _available_conversations(character: Dictionary) -> Array:
	var available: Array = []
	for conversation: Variant in character.get("conversations", []):
		if conversation is Dictionary and DialogueService.can_begin(str(conversation.get("id", ""))).get("ok", false):
			available.append(conversation)
	return available


func _on_conversation_selected(conversation_id: String) -> void:
	_update_world_location(false)
	var result: Dictionary = DialogueService.begin(conversation_id)
	if not result.get("ok", false):
		status_label.text = str(result.get("errors", ["That conversation is not available right now."])[0])
		return
	get_tree().change_scene_to_file(AppConstants.VN_DIALOGUE_SCENE)


func _on_ambient_chat_selected(character_id: String, line: String) -> void:
	TimeService.advance_minutes(5, "home.ambient_chat:%s" % character_id)
	status_label.text = "%s: “%s”" % [_first_name(character_id), line]
	_sync_household_schedule(true)
	_render_room()


func _ambient_line(character: Dictionary) -> String:
	var block: String = str(GameState.current_state["clock"]["block"])
	for entry: Variant in character.get("ambient_dialogue", []):
		if entry is Dictionary and block in entry.get("blocks", []):
			return str(entry.get("line", "")).replace("{player_first_name}", str(GameState.current_state["player"]["identity"]["first_name"]))
	return ""


func _sync_household_schedule(force: bool = false) -> void:
	if _schedule_engine == null or not GameState.has_active_game():
		return
	var clock: Dictionary = GameState.current_state["clock"]
	var bathroom_slot: int = floori(float(clock.get("minute_within_block", 0)) / float(BATHROOM_SLOT_MINUTES))
	var signature: String = "%s:%s:%s:%s:%s" % [clock.get("year", 1), clock.get("month", 1), clock.get("day", 1), clock.get("block", ""), bathroom_slot]
	if not force and signature == _schedule_signature:
		return
	_schedule_signature = signature
	QuestService.sync_automatic_activations("home.schedule_tick")
	var sync_result: Dictionary = _schedule_engine.synchronize_npc_states(GameState.current_state, HOUSEHOLD_CHARACTER_IDS)
	_npc_resolutions = sync_result.get("resolutions", {})
	if sync_result.get("changed", false):
		GameState.replace_state(sync_result["state"])
	if is_node_ready():
		_rebuild_room_buttons()
		_refresh_directional_navigation()
		_rebuild_character_stage()
		_rebuild_room_actions()


func _private_door_locked(room_id: String) -> bool:
	if not PRIVATE_DOOR_RULES.has(room_id) or not GameState.has_active_game():
		return false
	var overrides: Variant = GameState.current_state["world_state"].get("world_flags", {}).get("hale_door_lock_overrides", {})
	if overrides is Dictionary and overrides.get(room_id) is bool:
		return bool(overrides[room_id])
	var rule: Dictionary = PRIVATE_DOOR_RULES[room_id]
	var clock: Dictionary = GameState.current_state["clock"]
	var block: String = str(clock.get("block", "morning"))
	if block in rule.get("always_locked_blocks", []):
		return true
	var stable_roll: int = (
		int(GameState.current_state["world_state"].get("random_seed", 0))
		+ int(clock.get("year", 1)) * 7919
		+ int(clock.get("month", 1)) * 811
		+ int(clock.get("day", 1)) * 97
		+ maxi(ACTIVITY_BLOCKS.find(block), 0) * 29
		+ int(rule.get("salt", 0))
	)
	return posmod(stable_roll, 100) < int(rule.get("chance_percent", 0))


func _bathroom_door_state() -> Dictionary:
	var available: Dictionary = {"status": "available", "occupant_id": "", "source": "none"}
	if not GameState.has_active_game():
		return available
	var world_flags: Dictionary = GameState.current_state["world_state"].get("world_flags", {})
	var override: Variant = world_flags.get("hale_bathroom_door_override", null)
	if override is bool:
		return {"status": "locked" if override else "available", "occupant_id": "", "source": "story_override"}
	if override is String and str(override) in ["available", "locked", "occupied_locked"]:
		return {"status": str(override), "occupant_id": "", "source": "story_override"}
	if override is Dictionary:
		var override_status: String = str(override.get("status", ""))
		if override_status in ["available", "locked", "occupied_locked"]:
			return {"status": override_status, "occupant_id": str(override.get("occupant_id", "")), "source": "story_override"}

	var at_home_ids: PackedStringArray = []
	for character_id: String in BATHROOM_OCCUPANT_IDS:
		var resolution: Dictionary = _npc_resolutions.get(character_id, {})
		if not bool(resolution.get("at_home", false)):
			continue
		at_home_ids.append(character_id)
		if str(resolution.get("room", "")) == "family_bathroom":
			return {"status": "occupied_locked", "occupant_id": character_id, "source": "household_schedule"}
	if at_home_ids.is_empty():
		return available

	var clock: Dictionary = GameState.current_state["clock"]
	var block: String = str(clock.get("block", "morning"))
	var busy_chance: int = int(BATHROOM_BUSY_CHANCES.get(block, 0))
	if busy_chance <= 0:
		return available
	var minute_slot: int = floori(float(clock.get("minute_within_block", 0)) / float(BATHROOM_SLOT_MINUTES))
	var stable_roll: int = (
		int(GameState.current_state["world_state"].get("random_seed", 0))
		+ int(clock.get("year", 1)) * 6151
		+ int(clock.get("month", 1)) * 647
		+ int(clock.get("day", 1)) * 83
		+ maxi(ACTIVITY_BLOCKS.find(block), 0) * 31
		+ minute_slot * 101
		+ 71
	)
	if posmod(stable_roll, 100) >= busy_chance:
		return available
	var occupant_index: int = posmod(floori(float(stable_roll) / 100.0), at_home_ids.size())
	return {"status": "occupied_locked", "occupant_id": at_home_ids[occupant_index], "source": "time_variation"}


func _first_name(character_id: String) -> String:
	var character: Variant = ContentRegistry.get_character(character_id)
	if character is Dictionary:
		return str(character.get("display_name", character_id)).get_slice(" ", 0)
	return character_id.replace("_", " ").capitalize()


func _open_wardrobe() -> void:
	_clear_container(wardrobe_list)
	var state: Dictionary = GameState.current_state
	var outfit: Dictionary = state["player"]["inventory"]["equipped_outfit"]
	for container: Variant in state["player"]["inventory"]["containers"]:
		if not container is Dictionary or str(container.get("id", "")) != "wardrobe_storage":
			continue
		for stack: Variant in container.get("items", []):
			if not stack is Dictionary:
				continue
			var item_id: String = str(stack.get("item_id", ""))
			var item: Variant = ContentRegistry.get_content("items", item_id)
			if not item is Dictionary or str(item.get("category", "")) != "clothing":
				continue
			var slot: String = str(item.get("slot", ""))
			var equipped: bool = str(outfit.get(slot, "")) == item_id
			var button: Button = Button.new()
			button.text = "%s%s — %s" % ["✓ " if equipped else "", item.get("name", item_id), slot.capitalize()]
			button.custom_minimum_size = Vector2(0, 42)
			button.pressed.connect(_on_equip_item.bind(item_id, slot))
			wardrobe_list.add_child(button)
	_refresh_outfit_text()
	wardrobe_panel.visible = true
	SettingsService.apply_accessibility(wardrobe_panel)


func _on_equip_item(item_id: String, slot: String) -> void:
	var result: Dictionary = SimulationService.apply_operation("inventory.equip", {"item_id": item_id, "wardrobe_slot": slot}, "home.wardrobe")
	if result.get("ok", false):
		status_label.text = "Outfit updated."
		_open_wardrobe()
	else:
		status_label.text = str(result.get("errors", ["Item could not be equipped."])[0])


func _refresh_outfit_text() -> void:
	var lines: PackedStringArray = ["[b]CURRENT OUTFIT[/b]"]
	var outfit: Dictionary = GameState.current_state["player"]["inventory"]["equipped_outfit"]
	for slot: Variant in outfit:
		var item: Variant = ContentRegistry.get_content("items", str(outfit[slot]))
		lines.append("%s: %s" % [str(slot).capitalize(), item.get("name", outfit[slot]) if item is Dictionary else outfit[slot]])
	outfit_text.text = "\n".join(lines)


func _toggle_quest_panel() -> void:
	quest_panel.visible = not quest_panel.visible
	if quest_panel.visible:
		var lines: PackedStringArray = ["[font_size=26][b]TRACKED QUESTS[/b][/font_size]"]
		var tracked: Array = GameState.current_state["quest_state"].get("tracked", [])
		for quest_id_value: Variant in tracked:
			var quest: Variant = ContentRegistry.get_content("quests", str(quest_id_value))
			if quest is Dictionary:
				var progress: Dictionary = QuestService.get_progress(str(quest_id_value))
				var counter: String = "\n[color=#86d6c5]%s • %s[/color]" % [progress.get("progress_label", "Completions"), progress.get("progress_text", "0/0")] if bool(progress.get("repeatable", false)) else ""
				lines.append("[b]%s[/b]\n%s%s" % [quest.get("title", quest.get("id", "Quest")), quest.get("summary", ""), counter])
		if tracked.is_empty():
			lines.append("Nothing is pinned. Open the phone's Quests app to track a discovered quest.")
		quest_text.text = "\n\n".join(lines)


func _refresh_hud() -> void:
	if not GameState.has_active_game() or not is_node_ready():
		return
	var state: Dictionary = GameState.current_state
	var clock: Dictionary = state["clock"]
	var month_index: int = clampi(int(clock["month"]) - 1, 0, MONTH_NAMES.size() - 1)
	clock_label.text = "%s • %s • %s %d" % [str(clock["weekday"]).capitalize(), str(clock["block"]).replace("_", " ").capitalize(), MONTH_NAMES[month_index], clock["day"]]
	var needs: Dictionary = state["player"]["needs"]
	needs_label.text = "Energy %d   Hunger %d   Hydration %d   Hygiene %d   Stress %d" % [int(needs["energy"]), int(needs["hunger"]), int(needs["hydration"]), int(needs["hygiene"]), int(needs["stress"])]


func _close_panels() -> void:
	wardrobe_panel.visible = false
	quest_panel.visible = false


func _on_close_panel_pressed() -> void:
	_close_panels()


func _on_phone_button_pressed() -> void:
	smartphone.open_phone()


func _on_map_button_pressed() -> void:
	smartphone.open_phone("city_map")


func _on_phone_opened() -> void:
	_close_panels()


func _on_phone_closed() -> void:
	_refresh_hud()


func _on_travel_completed(destination: String) -> void:
	var location_id: String = destination.get_slice(".", 0)
	get_tree().change_scene_to_file(AppConstants.HALE_HOME_SCENE if location_id == "hale_home" else AppConstants.CITY_LOCATION_SCENE)


func _clear_container(container: Container) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _apply_accessibility_settings() -> void:
	SettingsService.apply_accessibility(self)
