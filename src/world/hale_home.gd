extends Node2D

const WALL_THICKNESS: float = 12.0
const INTERACTION_DISTANCE: float = 88.0
const HouseholdScheduleEngineScript: GDScript = preload("res://src/world/household_schedule_engine.gd")
const HouseholdNpcActorScene: PackedScene = preload("res://scenes/world/household_npc_actor.tscn")
const HOUSEHOLD_CHARACTER_IDS: PackedStringArray = ["elena_reyes_hale", "daniel_hale", "lily_hale"]
const MONTH_NAMES: PackedStringArray = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
]

@onready var player: CharacterBody2D = %Player
@onready var room_label: Label = %RoomLabel
@onready var clock_label: Label = %ClockLabel
@onready var needs_label: Label = %NeedsLabel
@onready var interaction_prompt: Label = %InteractionPrompt
@onready var status_label: Label = %StatusLabel
@onready var action_panel: PanelContainer = %ActionPanel
@onready var action_title: Label = %ActionTitle
@onready var action_buttons: VBoxContainer = %ActionButtons
@onready var wardrobe_panel: PanelContainer = %WardrobePanel
@onready var wardrobe_list: VBoxContainer = %WardrobeList
@onready var outfit_text: RichTextLabel = %OutfitText
@onready var quest_panel: PanelContainer = %QuestPanel
@onready var quest_text: RichTextLabel = %QuestText
@onready var smartphone: Control = %Smartphone
@onready var household_actors: Node2D = %HouseholdActors

var _rooms: Dictionary = {
	"player_bedroom": {"name": "Player Bedroom", "rect": Rect2(20, 20, 400, 330), "color": Color("253b49")},
	"upstairs_hall": {"name": "Upstairs Hall", "rect": Rect2(420, 20, 480, 330), "color": Color("293f47")},
	"family_bathroom": {"name": "Family Bathroom", "rect": Rect2(900, 20, 300, 330), "color": Color("244951")},
	"lily_bedroom": {"name": "Lily's Bedroom — Private", "rect": Rect2(1200, 20, 380, 330), "color": Color("483747")},
	"living_room": {"name": "Living Room", "rect": Rect2(20, 350, 480, 340), "color": Color("34443d")},
	"dining_room": {"name": "Dining Room", "rect": Rect2(500, 350, 300, 340), "color": Color("484335")},
	"kitchen": {"name": "Kitchen", "rect": Rect2(800, 350, 400, 340), "color": Color("3e4938")},
	"parents_bedroom": {"name": "Parents' Bedroom — Private", "rect": Rect2(1200, 350, 380, 340), "color": Color("453737")},
	"backyard": {"name": "Backyard", "rect": Rect2(20, 690, 380, 290), "color": Color("294735")},
	"laundry_room": {"name": "Laundry Room", "rect": Rect2(400, 690, 250, 290), "color": Color("34454b")},
	"garage": {"name": "Garage", "rect": Rect2(650, 690, 500, 290), "color": Color("3d4144")},
	"front_yard": {"name": "Front Yard", "rect": Rect2(1150, 690, 430, 290), "color": Color("334a36")},
}
var _interactions: Array = [
	{"id": "bed", "room": "player_bedroom", "position": Vector2(155, 118), "label": "Bed", "actions": ["nap", "sleep"]},
	{"id": "wardrobe", "room": "player_bedroom", "position": Vector2(365, 92), "label": "Wardrobe", "special": "wardrobe"},
	{"id": "desk", "room": "player_bedroom", "position": Vector2(350, 288), "label": "Desk and Phone", "special": "phone"},
	{"id": "bath_fixture", "room": "family_bathroom", "position": Vector2(1105, 105), "label": "Shower and Bath", "actions": ["shower", "bath"]},
	{"id": "bath_sink", "room": "family_bathroom", "position": Vector2(960, 275), "label": "Bathroom Sink", "actions": ["brush_teeth", "groom"]},
	{"id": "lily_door", "room": "upstairs_hall", "position": Vector2(1180, 175), "label": "Lily's Door", "special": "lily_door"},
	{"id": "parents_door", "room": "kitchen", "position": Vector2(1180, 520), "label": "Parents' Door", "special": "parents_door"},
	{"id": "sofa", "room": "living_room", "position": Vector2(180, 500), "label": "Living Room Sofa", "special": "sofa"},
	{"id": "dining_table", "room": "dining_room", "position": Vector2(650, 520), "label": "Dining Table", "actions": ["eat_snack"]},
	{"id": "kitchen_counter", "room": "kitchen", "position": Vector2(1000, 500), "label": "Kitchen Counter", "actions": ["drink_water", "eat_snack", "cook_basic_meal"]},
	{"id": "laundry", "room": "laundry_room", "position": Vector2(525, 815), "label": "Washer and Dryer", "actions": ["do_laundry"]},
	{"id": "family_car", "room": "garage", "position": Vector2(900, 835), "label": "Family Car", "special": "family_car"},
	{"id": "backyard", "room": "backyard", "position": Vector2(185, 830), "label": "Backyard", "special": "backyard"},
	{"id": "front_gate", "room": "front_yard", "position": Vector2(1410, 910), "label": "Leave Home", "special": "leave_home"},
]
var _wall_segments: Array = []
var _current_room: String = "player_bedroom"
var _nearest_interaction: Dictionary = {}
var _schedule_engine: RefCounted
var _npc_resolutions: Dictionary = {}
var _schedule_signature: String = ""


func _ready() -> void:
	if not GameState.has_active_game():
		get_tree().change_scene_to_file(AppConstants.MAIN_MENU_SCENE)
		return
	_build_rooms()
	_build_walls()
	_schedule_engine = HouseholdScheduleEngineScript.new(ContentRegistry)
	player.interact_requested.connect(_on_interact_requested)
	smartphone.phone_opened.connect(_on_phone_opened)
	smartphone.phone_closed.connect(_on_phone_closed)
	_restore_player_location()
	_sync_household_schedule(true)
	_refresh_hud()
	queue_redraw()


func _process(_delta: float) -> void:
	_sync_household_schedule()
	_nearest_interaction = _find_nearest_interaction(player.global_position)
	if _nearest_interaction.is_empty() or _modal_open():
		interaction_prompt.text = ""
	else:
		interaction_prompt.text = "E / A — %s" % _nearest_interaction["label"]
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if smartphone.is_open():
		if event.is_action_pressed("cancel") or event.is_action_pressed("phone"):
			smartphone.close_phone()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("cancel") and _modal_open():
		_close_panels()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quest_tracker") and not action_panel.visible and not wardrobe_panel.visible:
		_toggle_quest_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("phone") and not _modal_open():
		smartphone.open_phone()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	for room_id: Variant in _rooms:
		var room: Dictionary = _rooms[room_id]
		var rect: Rect2 = room["rect"]
		draw_rect(rect, room["color"], true)
		draw_rect(rect, Color("72878b"), false, 2.0)
		draw_string(
			ThemeDB.fallback_font,
			rect.position + Vector2(14, 28),
			str(room["name"]),
			HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 28,
			17,
			Color(0.83, 0.89, 0.89, 0.72)
		)
	for segment: Variant in _wall_segments:
		draw_line(segment[0], segment[1], Color("c3d0cf"), WALL_THICKNESS, true)
	for interaction: Dictionary in _interactions:
		var marker_color: Color = Color("e9a86c") if not interaction.has("special") else Color("67c6c3")
		draw_circle(interaction["position"], 10.0, marker_color)
		draw_circle(interaction["position"], 10.0, Color("eef6f5"), false, 2.0)


func _build_rooms() -> void:
	var room_parent: Node2D = Node2D.new()
	room_parent.name = "RoomAreas"
	add_child(room_parent)
	for room_id: Variant in _rooms:
		var room: Dictionary = _rooms[room_id]
		var rect: Rect2 = room["rect"]
		var area: Area2D = Area2D.new()
		area.name = str(room_id).to_pascal_case()
		area.collision_layer = 0
		area.collision_mask = 1
		area.position = rect.get_center()
		var shape_node: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = rect.size - Vector2(WALL_THICKNESS * 2.0, WALL_THICKNESS * 2.0)
		shape_node.shape = shape
		area.add_child(shape_node)
		area.body_entered.connect(_on_room_entered.bind(str(room_id)))
		room_parent.add_child(area)


func _build_walls() -> void:
	var wall_parent: Node2D = Node2D.new()
	wall_parent.name = "Walls"
	add_child(wall_parent)
	# Outer shell. The front gate becomes a transition once city travel is implemented.
	_add_wall(wall_parent, Vector2(20, 20), Vector2(1580, 20))
	_add_wall(wall_parent, Vector2(20, 20), Vector2(20, 980))
	_add_wall(wall_parent, Vector2(1580, 20), Vector2(1580, 980))
	_add_wall(wall_parent, Vector2(20, 980), Vector2(1580, 980))
	# Top-row vertical divisions. Lily's room remains fully private.
	_add_vertical_with_gap(wall_parent, 420, 20, 350, 150, 230)
	_add_vertical_with_gap(wall_parent, 900, 20, 350, 145, 225)
	_add_wall(wall_parent, Vector2(1200, 20), Vector2(1200, 350))
	# Middle-row divisions. The parents' bedroom remains fully private.
	_add_vertical_with_gap(wall_parent, 500, 350, 690, 480, 560)
	_add_vertical_with_gap(wall_parent, 800, 350, 690, 480, 560)
	_add_wall(wall_parent, Vector2(1200, 350), Vector2(1200, 690))
	# Ground/outdoor divisions.
	_add_vertical_with_gap(wall_parent, 400, 690, 980, 790, 870)
	_add_vertical_with_gap(wall_parent, 650, 690, 980, 790, 870)
	_add_vertical_with_gap(wall_parent, 1150, 690, 980, 790, 870)
	# Horizontal divisions between floors, with open doorways where permitted.
	_add_horizontal_sections(wall_parent, 350, [20, 180, 260, 620, 700, 1010, 1090, 1580])
	_add_horizontal_sections(wall_parent, 690, [20, 180, 260, 560, 640, 960, 1040, 1580])


func _add_vertical_with_gap(
	parent: Node2D,
	x: float,
	start_y: float,
	end_y: float,
	gap_start: float,
	gap_end: float
) -> void:
	_add_wall(parent, Vector2(x, start_y), Vector2(x, gap_start))
	_add_wall(parent, Vector2(x, gap_end), Vector2(x, end_y))


func _add_horizontal_sections(parent: Node2D, y: float, points: Array) -> void:
	for index: int in range(0, points.size() - 1, 2):
		_add_wall(parent, Vector2(points[index], y), Vector2(points[index + 1], y))


func _add_wall(parent: Node2D, start: Vector2, end: Vector2) -> void:
	_wall_segments.append([start, end])
	var body: StaticBody2D = StaticBody2D.new()
	body.position = (start + end) * 0.5
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	if is_equal_approx(start.y, end.y):
		shape.size = Vector2(absf(end.x - start.x) + WALL_THICKNESS, WALL_THICKNESS)
	else:
		shape.size = Vector2(WALL_THICKNESS, absf(end.y - start.y) + WALL_THICKNESS)
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _on_room_entered(body: Node2D, room_id: String) -> void:
	if body == player:
		_set_current_room(room_id)


func _set_current_room(room_id: String) -> void:
	if not _rooms.has(room_id):
		return
	_current_room = room_id
	room_label.text = str(_rooms[room_id]["name"])
	var location_path: String = "hale_home.%s" % room_id
	if str(GameState.current_state["world_state"].get("current_location", "")) == location_path:
		return
	var next_state: Dictionary = GameState.current_state.duplicate(true)
	next_state["world_state"]["current_location"] = location_path
	GameState.replace_state(next_state)


func _find_nearest_interaction(world_position: Vector2) -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance: float = INTERACTION_DISTANCE
	for interaction: Dictionary in _interactions:
		if str(interaction["room"]) != _current_room:
			continue
		var distance: float = world_position.distance_to(interaction["position"])
		if distance < closest_distance:
			closest = interaction
			closest_distance = distance
	for character_id: Variant in _npc_resolutions:
		var resolution: Dictionary = _npc_resolutions[character_id]
		if not bool(resolution.get("present", false)) or str(resolution.get("room", "")) != _current_room:
			continue
		var coordinates: Array = resolution.get("position", [])
		if coordinates.size() != 2:
			continue
		var npc_position: Vector2 = Vector2(float(coordinates[0]), float(coordinates[1]))
		var distance: float = world_position.distance_to(npc_position)
		if distance < closest_distance:
			closest = {
				"id": "npc:%s" % character_id,
				"room": resolution.get("room", ""),
				"position": npc_position,
				"label": "Talk to %s" % _first_name(str(character_id)),
				"character_id": str(character_id),
			}
			closest_distance = distance
	return closest


func _on_interact_requested(_world_position: Vector2) -> void:
	if _nearest_interaction.is_empty() or _modal_open():
		return
	if _nearest_interaction.has("character_id"):
		_open_npc_panel(str(_nearest_interaction["character_id"]))
	elif _nearest_interaction.has("actions"):
		_open_action_panel(_nearest_interaction)
	else:
		_handle_special(str(_nearest_interaction.get("special", "")))


func _open_action_panel(interaction: Dictionary) -> void:
	_clear_container(action_buttons)
	action_title.text = str(interaction["label"])
	for action_id: Variant in interaction["actions"]:
		var action: Variant = ContentRegistry.get_content("actions", str(action_id))
		if not action is Dictionary:
			continue
		var button: Button = Button.new()
		button.text = "%s — %s" % [action.get("name", action_id), action.get("description", "")]
		button.custom_minimum_size = Vector2(0, 46)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_action_selected.bind(str(action_id)))
		action_buttons.add_child(button)
	action_panel.visible = true
	player.movement_enabled = false
	if action_buttons.get_child_count() > 0:
		action_buttons.get_child(0).grab_focus()


func _on_action_selected(action_id: String) -> void:
	var result: Dictionary = HomeActionService.perform(action_id)
	if result.get("ok", false):
		status_label.text = "%s completed. Time and state updated." % result["action"].get("name", action_id)
	else:
		status_label.text = str(result.get("errors", ["Action could not be completed."])[0])
	_close_panels()
	_refresh_hud()


func _handle_special(special: String) -> void:
	match special:
		"wardrobe":
			_open_wardrobe()
		"phone":
			smartphone.open_phone()
		"lily_door":
			status_label.text = "You knock. Lily asks for privacy right now, so the door remains closed."
		"parents_door":
			status_label.text = "Your parents' room is private. You cannot enter without permission."
		"sofa":
			status_label.text = "The living room is available for household conversations and relaxation."
		"family_car":
			var permission: String = str(GameState.current_state["player"]["transportation"]["family_car_permission"])
			status_label.text = "Family car access: %s. City driving will unlock with travel." % permission.replace("_", " ")
		"backyard":
			status_label.text = "The backyard can host exercise, relaxation, and small gatherings."
		"leave_home":
			status_label.text = "The front gate leads into Port Alder. City travel is the upcoming milestone."


func _open_npc_panel(character_id: String) -> void:
	var character: Variant = ContentRegistry.get_character(character_id)
	if not character is Dictionary:
		return
	_clear_container(action_buttons)
	action_title.text = "%s • %s" % [character.get("display_name", character_id), _npc_resolutions.get(character_id, {}).get("activity_label", "At home")]
	var conversations: Array = _available_conversations(character)
	for conversation: Dictionary in conversations:
		var button: Button = Button.new()
		button.text = "Talk — %s" % conversation.get("title", str(conversation.get("id", "Conversation")).replace("_", " ").capitalize())
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(_on_conversation_selected.bind(str(conversation.get("id", ""))))
		action_buttons.add_child(button)
	var ambient_line: String = _ambient_line(character)
	if not ambient_line.is_empty():
		var chat_button: Button = Button.new()
		chat_button.text = "Chat"
		chat_button.custom_minimum_size = Vector2(0, 48)
		chat_button.pressed.connect(_on_ambient_chat_selected.bind(character_id, ambient_line))
		action_buttons.add_child(chat_button)
	if action_buttons.get_child_count() == 0:
		var unavailable: Button = Button.new()
		unavailable.text = "%s has nothing new to discuss right now." % _first_name(character_id)
		unavailable.disabled = true
		action_buttons.add_child(unavailable)
	action_panel.visible = true
	player.movement_enabled = false
	if action_buttons.get_child_count() > 0:
		action_buttons.get_child(0).grab_focus()


func _available_conversations(character: Dictionary) -> Array:
	var available: Array = []
	for conversation: Variant in character.get("conversations", []):
		if not conversation is Dictionary:
			continue
		var availability: Dictionary = DialogueService.can_begin(str(conversation.get("id", "")))
		if availability.get("ok", false):
			available.append(conversation)
	return available


func _on_conversation_selected(conversation_id: String) -> void:
	_remember_player_position()
	var result: Dictionary = DialogueService.begin(conversation_id)
	if not result.get("ok", false):
		status_label.text = str(result.get("errors", ["That conversation is not available right now."])[0])
		return
	get_tree().change_scene_to_file(AppConstants.VN_DIALOGUE_SCENE)


func _on_ambient_chat_selected(character_id: String, line: String) -> void:
	TimeService.advance_minutes(5, "home.ambient_chat:%s" % character_id)
	status_label.text = "%s: “%s”" % [_first_name(character_id), line]
	_close_panels()


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
	var signature: String = "%s:%s:%s:%s" % [clock.get("year", 1), clock.get("month", 1), clock.get("day", 1), clock.get("block", "")]
	if not force and signature == _schedule_signature:
		return
	_schedule_signature = signature
	QuestService.sync_automatic_activations("home.schedule_tick")
	var sync_result: Dictionary = _schedule_engine.synchronize_npc_states(GameState.current_state, HOUSEHOLD_CHARACTER_IDS)
	_npc_resolutions = sync_result.get("resolutions", {})
	if sync_result.get("changed", false):
		GameState.replace_state(sync_result["state"])
	_rebuild_household_actors()


func _rebuild_household_actors() -> void:
	for child: Node in household_actors.get_children():
		household_actors.remove_child(child)
		child.queue_free()
	for character_id: Variant in _npc_resolutions:
		var resolution: Dictionary = _npc_resolutions[character_id]
		if not bool(resolution.get("present", false)):
			continue
		var character: Dictionary = ContentRegistry.get_character(str(character_id))
		var color_hex: String = str(character.get("home_routine", {}).get("actor_color", "67c6c3"))
		var actor: CharacterBody2D = HouseholdNpcActorScene.instantiate()
		household_actors.add_child(actor)
		actor.configure(resolution, color_hex)


func _restore_player_location() -> void:
	var world: Dictionary = GameState.current_state["world_state"]
	var location: String = str(world.get("current_location", "hale_home.player_bedroom"))
	var room_id: String = location.trim_prefix("hale_home.") if location.begins_with("hale_home.") else "player_bedroom"
	if not _rooms.has(room_id):
		room_id = "player_bedroom"
	var saved_position: Array = world.get("home_player_position", [])
	if saved_position.size() == 2:
		player.position = Vector2(float(saved_position[0]), float(saved_position[1]))
	_set_current_room(room_id)


func _remember_player_position() -> void:
	var next_state: Dictionary = GameState.current_state.duplicate(true)
	next_state["world_state"]["current_location"] = "hale_home.%s" % _current_room
	next_state["world_state"]["home_player_position"] = [player.position.x, player.position.y]
	GameState.replace_state(next_state)


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
	player.movement_enabled = false
	if wardrobe_list.get_child_count() > 0:
		wardrobe_list.get_child(0).grab_focus()


func _on_equip_item(item_id: String, slot: String) -> void:
	var result: Dictionary = SimulationService.apply_operation(
		"inventory.equip",
		{"item_id": item_id, "wardrobe_slot": slot},
		"home.wardrobe"
	)
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
	player.movement_enabled = not quest_panel.visible
	if quest_panel.visible:
		var lines: PackedStringArray = ["[font_size=26][b]ACTIVE QUESTS[/b][/font_size]"]
		for quest: Variant in QuestService.get_active_quests():
			if quest is Dictionary:
				lines.append("[b]%s[/b]\n%s" % [quest.get("title", quest.get("id", "Quest")), quest.get("summary", "")])
		quest_text.text = "\n\n".join(lines)


func _refresh_hud() -> void:
	if not GameState.has_active_game():
		return
	var state: Dictionary = GameState.current_state
	var clock: Dictionary = state["clock"]
	var month_index: int = clampi(int(clock["month"]) - 1, 0, MONTH_NAMES.size() - 1)
	clock_label.text = "%s • %s • %s" % [
		str(clock["weekday"]).capitalize(),
		str(clock["block"]).replace("_", " ").capitalize(),
		"%s %d" % [MONTH_NAMES[month_index], clock["day"]],
	]
	var needs: Dictionary = state["player"]["needs"]
	needs_label.text = "Energy %d   Hunger %d   Hydration %d   Hygiene %d   Stress %d" % [
		int(needs["energy"]), int(needs["hunger"]), int(needs["hydration"]),
		int(needs["hygiene"]), int(needs["stress"]),
	]


func _modal_open() -> bool:
	return action_panel.visible or wardrobe_panel.visible or quest_panel.visible or smartphone.is_open()


func _close_panels() -> void:
	action_panel.visible = false
	wardrobe_panel.visible = false
	quest_panel.visible = false
	player.movement_enabled = true


func _clear_container(container: Container) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_close_panel_pressed() -> void:
	_close_panels()


func _on_phone_opened() -> void:
	player.movement_enabled = false


func _on_phone_closed() -> void:
	player.movement_enabled = true
