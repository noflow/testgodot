extends Control

signal phone_opened
signal phone_closed
signal travel_completed(destination: String)

const APP_ORDER: PackedStringArray = [
	"character_profile", "contacts", "messages", "calendar", "quests",
	"relationships", "city_map", "weather", "settings",
]
const BLOCKS: PackedStringArray = [
	"early_morning", "morning", "lunch", "afternoon", "evening", "late_evening", "night",
]
const WEEKDAYS: PackedStringArray = [
	"monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
]
const MONTH_NAMES: PackedStringArray = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
]

@onready var phone_clock: Label = %PhoneClock
@onready var app_buttons: VBoxContainer = %AppButtons
@onready var app_title: Label = %AppTitle
@onready var app_content: RichTextLabel = %AppContent
@onready var app_actions: VBoxContainer = %AppActions
@onready var phone_status: Label = %PhoneStatus
@onready var scheduler_panel: PanelContainer = %SchedulerPanel
@onready var contact_option: OptionButton = %ContactOption
@onready var type_option: OptionButton = %TypeOption
@onready var day_option: OptionButton = %DayOption
@onready var block_option: OptionButton = %BlockOption
@onready var scheduler_status: Label = %SchedulerStatus
@onready var route_panel: PanelContainer = %RoutePanel
@onready var route_origin: Label = %RouteOrigin
@onready var route_destination: Label = %RouteDestination
@onready var route_option: OptionButton = %RouteOption
@onready var route_summary: RichTextLabel = %RouteSummary
@onready var route_status: Label = %RouteStatus
@onready var confirm_travel_button: Button = %ConfirmTravelButton

var _current_app: String = "character_profile"
var _selected_contact: String = ""
var _selected_route_destination: String = ""


func _ready() -> void:
	_build_app_buttons()
	visible = false


func open_phone(default_app: String = "character_profile") -> void:
	if not GameState.has_active_game():
		return
	PhoneService.sync_messages()
	visible = true
	scheduler_panel.visible = false
	route_panel.visible = false
	_show_app(default_app)
	phone_opened.emit()
	if app_buttons.get_child_count() > 0:
		app_buttons.get_child(0).grab_focus()


func close_phone() -> void:
	if not visible:
		return
	scheduler_panel.visible = false
	route_panel.visible = false
	visible = false
	phone_closed.emit()


func is_open() -> bool:
	return visible


func _build_app_buttons() -> void:
	_clear_container(app_buttons)
	for app_id: String in APP_ORDER:
		var definition: Variant = ContentRegistry.get_content("phone_apps", app_id)
		if not definition is Dictionary:
			continue
		var button: Button = Button.new()
		button.name = "%sButton" % app_id.to_pascal_case()
		button.text = "%s  %s" % [definition.get("icon", "•"), definition.get("name", app_id)]
		button.custom_minimum_size = Vector2(190, 42)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_show_app.bind(app_id))
		app_buttons.add_child(button)


func _show_app(app_id: String) -> void:
	var unlocked: Array = GameState.current_state["player"]["phone"].get("unlocked_apps", [])
	if app_id not in unlocked:
		phone_status.text = "%s is still locked." % app_id.replace("_", " ").capitalize()
		return
	_current_app = app_id
	_clear_container(app_actions)
	phone_status.text = ""
	_refresh_clock()
	match app_id:
		"character_profile":
			_render_profile()
		"contacts":
			_render_contacts()
		"messages":
			_render_messages()
		"calendar":
			_render_calendar()
		"quests":
			_render_quests()
		"relationships":
			_render_relationships()
		"city_map":
			_render_map()
		"weather":
			_render_weather()
		"settings":
			_render_settings()


func _refresh_clock() -> void:
	var clock: Dictionary = GameState.current_state["clock"]
	phone_clock.text = "%s • %s • %s %d" % [
		str(clock["weekday"]).capitalize(),
		str(clock["block"]).replace("_", " ").capitalize(),
		MONTH_NAMES[clampi(int(clock["month"]) - 1, 0, 11)],
		int(clock["day"]),
	]


func _render_profile() -> void:
	app_title.text = "CHARACTER PROFILE"
	var state: Dictionary = GameState.current_state
	var player: Dictionary = state["player"]
	var identity: Dictionary = player["identity"]
	var lines: PackedStringArray = [
		"[font_size=25]%s %s[/font_size]" % [identity["first_name"], identity["last_name"]],
		"Age %d • %s • Birthday %s" % [identity["age"], str(identity["gender_identity"]).capitalize(), identity["birthday"]],
		"Life direction: [color=#e9a86c]%s[/color]" % ("Undecided" if player.get("life_path") == null else str(player["life_path"]).replace("_", " ").capitalize()),
		"",
		"NEEDS",
		_format_number_grid(player["needs"]),
		"",
		"ATTRIBUTES",
		_format_number_grid(player["attributes"]),
		"",
		"TRAITS AND VALUES",
		"Positive: %s" % _joined_labels(player["selected_traits"].get("positive", [])),
		"Challenging: %s" % _joined_labels(player["selected_traits"].get("challenging", [])),
		"Values: %s" % _joined_labels(player["selected_traits"].get("core_values", [])),
		"Hobbies: %s" % _joined_labels(player["selected_traits"].get("hobbies", [])),
		"",
		"SKILLS — LEVEL 0–250",
		_format_skills(player.get("skills", {})),
		"",
		"MONEY",
		_format_accounts(player["economy"]["accounts"]),
		"",
		"CURRENT OUTFIT",
		_format_outfit(player["inventory"]["equipped_outfit"]),
	]
	app_content.text = "\n".join(lines)


func _render_contacts() -> void:
	app_title.text = "CONTACTS"
	var lines: PackedStringArray = []
	for character_id_value: Variant in GameState.current_state["player"]["phone"].get("known_contacts", []):
		var character_id: String = str(character_id_value)
		var character: Dictionary = ContentRegistry.get_character(character_id)
		var profile: Dictionary = character.get("profile", {})
		var availability: String = _availability_now(character)
		lines.append("[font_size=21]%s[/font_size]\nAge %d • %s\n%s\n[color=#9eb4b5]%s[/color]" % [
			character.get("display_name", character_id),
			int(profile.get("age", 0)),
			str(profile.get("gender_identity", "unknown")).capitalize(),
			profile.get("occupation", "Unknown occupation"),
			availability,
		])
		_add_action_button("Message %s" % character.get("display_name", character_id), _open_message_thread.bind(character_id))
	app_content.text = "\n\n".join(lines)


func _render_messages() -> void:
	_clear_container(app_actions)
	app_title.text = "MESSAGES"
	var contacts: Array = GameState.current_state["player"]["phone"].get("known_contacts", [])
	if _selected_contact.is_empty() and not contacts.is_empty():
		_selected_contact = str(contacts[0])
	if _selected_contact.is_empty():
		app_content.text = "No contacts are available."
		return
	if _selected_contact in GameState.current_state["player"]["phone"].get("unread_threads", []):
		PhoneService.mark_thread_read(_selected_contact)
	var contact: Dictionary = ContentRegistry.get_character(_selected_contact)
	var thread: Dictionary = GameState.current_state["player"]["phone"].get("message_threads", {}).get(_selected_contact, {})
	var lines: PackedStringArray = ["[font_size=23]%s[/font_size]" % contact.get("display_name", _selected_contact)]
	for message: Variant in thread.get("messages", []):
		if not message is Dictionary:
			continue
		var from_player: bool = str(message.get("sender", "")) == "player"
		var speaker: String = "You" if from_player else str(contact.get("display_name", _selected_contact))
		var color: String = "#67c6c3" if from_player else "#e9a86c"
		lines.append("[color=%s]%s • %s[/color]\n%s" % [color, speaker, _friendly_timestamp(str(message.get("timestamp", ""))), message.get("text", "")])
	app_content.text = "\n\n".join(lines) if lines.size() > 1 else "%s\n\nNo messages yet." % lines[0]
	_add_pending_reply_buttons(thread)
	for character_id_value: Variant in contacts:
		var character_id: String = str(character_id_value)
		var character: Dictionary = ContentRegistry.get_character(character_id)
		var unread: bool = character_id in GameState.current_state["player"]["phone"].get("unread_threads", [])
		_add_action_button("%s%s" % ["● " if unread else "", character.get("display_name", character_id)], _open_message_thread.bind(character_id))


func _render_calendar() -> void:
	_clear_container(app_actions)
	app_title.text = "CALENDAR"
	var calendar: Dictionary = GameState.current_state["calendar_state"]
	var lines: PackedStringArray = []
	for calendar_event: Variant in calendar.get("events", []):
		if not calendar_event is Dictionary:
			continue
		var status: String = str(calendar_event.get("status", "scheduled"))
		var title: String = str(calendar_event.get("title", calendar_event.get("source", calendar_event.get("id", "Plan")))).replace("_", " ").capitalize()
		var participants: PackedStringArray = []
		for participant: Variant in calendar_event.get("participants", []):
			participants.append(_character_name(str(participant)))
		lines.append("%s\n%s • %s\n%s%s" % [
			title,
			calendar_event.get("date", "Unscheduled"),
			str(calendar_event.get("block", "")).replace("_", " ").capitalize(),
			"With %s • " % ", ".join(participants) if not participants.is_empty() else "",
			status.capitalize(),
		])
		if status == "scheduled" and str(calendar_event.get("source", "")) != "opening_future_talk":
			_add_action_button("Cancel %s" % title, _cancel_calendar_event.bind(str(calendar_event.get("id", ""))))
	var warning_count: int = 0
	for conflict: Variant in calendar.get("conflicts", []):
		if conflict is Dictionary and str(conflict.get("status", "warning")) == "warning":
			warning_count += 1
	if warning_count > 0:
		lines.append("[color=#ef7777]CONFLICT WARNINGS: %d[/color]\nOverlapping optional plans are allowed, but you must resolve them before attending." % warning_count)
	app_content.text = "\n\n".join(lines) if not lines.is_empty() else "No plans are scheduled."
	_add_action_button("+ Add Plan", _open_scheduler)


func _render_quests() -> void:
	app_title.text = "QUESTS"
	var state: Dictionary = GameState.current_state
	var lines: PackedStringArray = ["ACTIVE"]
	for quest_id_value: Variant in state["quest_state"].get("active", []):
		var quest_id: String = str(quest_id_value)
		var quest: Dictionary = ContentRegistry.get_content("quests", quest_id)
		lines.append("[font_size=21]%s[/font_size]\n%s" % [quest.get("title", quest_id), quest.get("summary", "")])
		for objective: Variant in QuestService.get_progress(quest_id).get("objectives", []):
			if objective is Dictionary:
				lines.append("%s %s" % ["✓" if objective.get("completed", false) else "○", objective.get("text", objective.get("id", "Objective"))])
	for section: String in ["completed", "deferred", "failed"]:
		lines.append("\n%s" % section.to_upper())
		var ids: Array = state["quest_state"].get(section, [])
		lines.append(_quest_names(ids) if not ids.is_empty() else "None")
	app_content.text = "\n".join(lines)


func _render_relationships() -> void:
	app_title.text = "RELATIONSHIPS"
	var lines: PackedStringArray = []
	for character_id_value: Variant in GameState.current_state["player"]["phone"].get("known_contacts", []):
		var character_id: String = str(character_id_value)
		var meters: Dictionary = GameState.current_state["relationships"].get(character_id, {})
		lines.append("[font_size=22]%s[/font_size]" % _character_name(character_id))
		lines.append("Friendship %d (%s) • Love %d (%s)\nAttraction %d • Lust %d\nTrust %d • Respect %d • Comfort %d\nJealousy %d • Resentment %d • Commitment %d" % [
			int(meters.get("friendship", 0)), _meter_level(int(meters.get("friendship", 0))),
			int(meters.get("love", 0)), _meter_level(int(meters.get("love", 0))),
			int(meters.get("attraction", 0)), int(meters.get("lust", 0)),
			int(meters.get("trust", 0)), int(meters.get("respect", 0)), int(meters.get("comfort", 0)),
			int(meters.get("jealousy", 0)), int(meters.get("resentment", 0)), int(meters.get("commitment", 0)),
		])
	app_content.text = "\n\n".join(lines)


func _render_map() -> void:
	_clear_container(app_actions)
	TravelService.record_map_viewed()
	app_title.text = "CITY MAP"
	var world: Dictionary = GameState.current_state["world_state"]
	var current_root: String = str(world["current_location"]).get_slice(".", 0)
	var lines: PackedStringArray = [
		"Current location: [color=#e9a86c]%s[/color]" % _location_name(str(world["current_location"])),
		"",
		"UNLOCKED DESTINATIONS",
	]
	for location_id_value: Variant in world.get("unlocked_locations", []):
		var location_id: String = str(location_id_value)
		var location: Variant = ContentRegistry.get_location(location_id)
		if location is Dictionary:
			var marker: String = "[color=#67c6c3]YOU ARE HERE[/color]" if location_id == current_root else str(location.get("district", "unknown")).replace("_", " ").capitalize()
			lines.append("• %s — %s" % [location.get("name", location_id), marker])
			if location_id != current_root:
				_add_action_button("Plan route to %s" % location.get("name", location_id), _open_route_planner.bind(location_id))
	lines.append("\nSelect a destination to compare walking, bus, taxi, and car routes. Closed destinations remain visible but cannot be confirmed.")
	app_content.text = "\n".join(lines)


func _open_route_planner(destination: String) -> void:
	var plan: Dictionary = TravelService.plan_routes(destination)
	if not plan.get("ok", false):
		phone_status.text = str(plan.get("errors", ["No route is available."])[0])
		return
	_selected_route_destination = destination
	route_origin.text = "From: %s" % _location_name(str(GameState.current_state["world_state"]["current_location"]))
	route_destination.text = "To: %s" % plan.get("destination_name", _location_name(destination))
	route_option.clear()
	var first_available: int = -1
	var viewed_modes: PackedStringArray = []
	for option: Variant in plan.get("options", []):
		if not option is Dictionary:
			continue
		var mode: String = str(option.get("mode", ""))
		viewed_modes.append(mode)
		var label: String = "%s • %d min • $%.2f" % [option.get("name", mode.capitalize()), option.get("minutes", 0), option.get("cost", 0.0)]
		if int(option.get("wait_minutes", 0)) > 0:
			label += " • includes %d min wait" % option["wait_minutes"]
		if not bool(option.get("available", false)):
			label += " • UNAVAILABLE"
		route_option.add_item(label)
		var index: int = route_option.item_count - 1
		route_option.set_item_metadata(index, option.duplicate(true))
		route_option.set_item_disabled(index, not bool(option.get("available", false)))
		if first_available < 0 and bool(option.get("available", false)):
			first_available = index
	TravelService.record_routes_viewed(destination, viewed_modes)
	confirm_travel_button.disabled = first_available < 0
	if first_available >= 0:
		route_option.select(first_available)
	else:
		route_option.select(0)
	route_status.text = "" if first_available >= 0 else "No route can be used right now. Review the closure or requirement below."
	_update_route_summary(route_option.selected)
	scheduler_panel.visible = false
	route_panel.visible = true


func _update_route_summary(index: int) -> void:
	if index < 0 or index >= route_option.item_count:
		route_summary.text = "No route selected."
		return
	var option: Variant = route_option.get_item_metadata(index)
	if not option is Dictionary:
		route_summary.text = "No route selected."
		return
	var lines: PackedStringArray = [
		"[font_size=22]%s[/font_size]" % option.get("name", "Route"),
		"Total time: %d minutes" % option.get("minutes", 0),
		"Arrival: %s • %s +%03d" % [str(option.get("arrival_weekday", "")).capitalize(), str(option.get("arrival_block", "")).replace("_", " ").capitalize(), option.get("arrival_minute_within_block", 0)],
		"Cost: $%.2f" % option.get("cost", 0.0),
	]
	var segment_labels: PackedStringArray = []
	for segment: Variant in option.get("segments", []):
		if segment is Dictionary:
			segment_labels.append("%s: %s → %s (%d min)" % [str(segment.get("mode", "")).capitalize(), _short_location_name(str(segment.get("from", ""))), _short_location_name(str(segment.get("to", ""))), segment.get("minutes", 0)])
	if not segment_labels.is_empty():
		lines.append("\nROUTE\n%s" % "\n".join(segment_labels))
	for warning: Variant in option.get("warnings", []):
		lines.append("[color=#e9a86c]Warning: %s[/color]" % warning)
	if not bool(option.get("available", false)):
		lines.append("[color=#ef7777]%s[/color]" % option.get("reason", "Unavailable"))
	route_summary.text = "\n".join(lines)


func _on_confirm_travel_pressed() -> void:
	var selected: Variant = route_option.get_selected_metadata()
	if not selected is Dictionary:
		route_status.text = "Choose an available route first."
		return
	var result: Dictionary = TravelService.travel(_selected_route_destination, str(selected.get("mode", "")))
	if not result.get("ok", false):
		route_status.text = str(result.get("errors", ["Travel could not be completed."])[0])
		return
	route_panel.visible = false
	visible = false
	phone_closed.emit()
	travel_completed.emit(str(result.get("destination", _selected_route_destination)))


func _on_route_option_selected(index: int) -> void:
	_update_route_summary(index)


func _on_close_route_pressed() -> void:
	route_panel.visible = false


func _render_weather() -> void:
	app_title.text = "WEATHER"
	var state: Dictionary = GameState.current_state
	var weather: Dictionary = state["world_state"]["weather"]
	var outfit: Dictionary = state["player"]["inventory"]["equipped_outfit"]
	var scores: Dictionary = _outfit_scores(outfit)
	var requirements: Dictionary = weather.get("clothing", {})
	var missing: PackedStringArray = []
	for slot: String in ["underwear", "shirt", "pants", "shoes"]:
		if str(outfit.get(slot, "")).is_empty():
			missing.append(slot.capitalize())
	var warnings: PackedStringArray = []
	if scores["warmth"] < int(requirements.get("minimum_warmth", 0)):
		warnings.append("Not warm enough")
	if scores["rain_protection"] < int(requirements.get("rain_protection", 0)):
		warnings.append("Rain protection too low")
	if scores["wind_protection"] < int(requirements.get("wind_protection", 0)):
		warnings.append("Wind protection too low")
	if not missing.is_empty():
		warnings.append("Missing: %s" % ", ".join(missing))
	var status: String = "OUTFIT SUITABLE" if warnings.is_empty() else " • ".join(warnings)
	var lines: PackedStringArray = [
		"[font_size=26]%s[/font_size]" % str(weather.get("condition", "unknown")).replace("_", " ").capitalize(),
		"Low %d°C • High %d°C • Rain %d%% • Wind %d km/h" % [weather.get("low_c", 0), weather.get("high_c", 0), weather.get("rain_chance", 0), weather.get("wind_kph", 0)],
		"",
		"OUTFIT CHECK",
		"Warmth %d / %d • Rain %d / %d • Wind %d / %d" % [scores["warmth"], requirements.get("minimum_warmth", 0), scores["rain_protection"], requirements.get("rain_protection", 0), scores["wind_protection"], requirements.get("wind_protection", 0)],
		"[color=%s]%s[/color]" % ["#67c6c3" if warnings.is_empty() else "#ef7777", status],
	]
	if requirements.get("warning") != null:
		lines.append("\n%s" % requirements["warning"])
	lines.append("\nOPENING-WEEK FORECAST")
	for day: Variant in ContentRegistry.get_package("opening_week_calendar").get("days", []):
		if day is Dictionary:
			lines.append("%s — %s, %d–%d°C, %d%% rain" % [str(day.get("weekday", "")).capitalize(), str(day.get("weather", {}).get("condition", "")).replace("_", " ").capitalize(), day.get("weather", {}).get("low_c", 0), day.get("weather", {}).get("high_c", 0), day.get("weather", {}).get("rain_chance", 0)])
	app_content.text = "\n".join(lines)


func _render_settings() -> void:
	_clear_container(app_actions)
	app_title.text = "SETTINGS"
	app_content.text = "ACCESSIBILITY\nText size: %d%%\nReduce motion: %s\nHigh contrast: %s\n\nAUDIO\nMaster volume: %d%%\nMusic: %d%%\nAmbience: %d%%\nUI: %d%%\nVoice: %d%%\n\nSettings save locally and apply immediately." % [
		int(SettingsService.text_scale * 100.0), _on_off(SettingsService.reduce_motion), _on_off(SettingsService.high_contrast),
		int(SettingsService.master_volume * 100.0), int(SettingsService.music_volume * 100.0), int(SettingsService.ambience_volume * 100.0), int(SettingsService.ui_volume * 100.0), int(SettingsService.voice_volume * 100.0),
	]
	_add_action_button("Cycle Text Size", _cycle_text_size)
	_add_action_button("Toggle Reduce Motion", _toggle_reduce_motion)
	_add_action_button("Toggle High Contrast", _toggle_high_contrast)
	_add_action_button("Master Volume −", _adjust_master_volume.bind(-0.1))
	_add_action_button("Master Volume +", _adjust_master_volume.bind(0.1))


func _open_message_thread(character_id: String) -> void:
	_selected_contact = character_id
	_show_app("messages")


func _add_pending_reply_buttons(thread: Dictionary) -> void:
	for index: int in range(thread.get("messages", []).size() - 1, -1, -1):
		var message: Variant = thread["messages"][index]
		if not message is Dictionary or str(message.get("sender", "")) == "player":
			continue
		var message_id: String = str(message.get("id", ""))
		if _thread_has_reply(thread, message_id):
			continue
		var definition: Dictionary = _message_definition(_selected_contact, message_id)
		for reply_index: int in definition.get("quick_replies", []).size():
			var reply: Dictionary = definition["quick_replies"][reply_index]
			_add_action_button("Reply: %s" % reply.get("text", ""), _reply_to_message.bind(message_id, reply_index))
		return


func _reply_to_message(message_id: String, reply_index: int) -> void:
	var result: Dictionary = PhoneService.reply_to_message(_selected_contact, message_id, reply_index)
	if not result.get("ok", false):
		phone_status.text = str(result.get("errors", ["Reply failed."])[0])
		return
	phone_status.text = "Reply sent. Five in-game minutes passed."
	_render_messages()
	var participant: String = str(result.get("scheduler_participant", ""))
	if not participant.is_empty():
		_open_scheduler(participant)


func _open_scheduler(preselected_contact: String = "") -> void:
	_populate_scheduler(preselected_contact)
	scheduler_status.text = "Required work, class, and NPC commitments block confirmation. Other overlaps create a warning."
	scheduler_panel.visible = true
	route_panel.visible = false


func _populate_scheduler(preselected_contact: String) -> void:
	contact_option.clear()
	contact_option.add_item("Personal — no guest")
	contact_option.set_item_metadata(0, "")
	var selected_index: int = 0
	for character_id_value: Variant in GameState.current_state["player"]["phone"].get("known_contacts", []):
		var character_id: String = str(character_id_value)
		contact_option.add_item(_character_name(character_id))
		contact_option.set_item_metadata(contact_option.item_count - 1, character_id)
		if character_id == preselected_contact:
			selected_index = contact_option.item_count - 1
	contact_option.select(selected_index)
	type_option.clear()
	for event_type: Variant in ContentRegistry.get_package("port_alder_phone_system").get("calendar_event_types", []):
		if event_type is Dictionary:
			type_option.add_item(str(event_type.get("name", event_type.get("id", "Plan"))))
			type_option.set_item_metadata(type_option.item_count - 1, event_type.duplicate(true))
	day_option.clear()
	for offset: int in 7:
		var day: Dictionary = _date_after_days(GameState.current_state["clock"], offset)
		day_option.add_item("%s • %s %d" % [str(day["weekday"]).capitalize(), MONTH_NAMES[int(day["month"]) - 1], day["day"]])
		day_option.set_item_metadata(day_option.item_count - 1, day)
	block_option.clear()
	for block: String in BLOCKS:
		block_option.add_item(block.replace("_", " ").capitalize())
		block_option.set_item_metadata(block_option.item_count - 1, block)
	block_option.select(maxi(BLOCKS.find(str(GameState.current_state["clock"]["block"])), 0))


func _on_confirm_schedule_pressed() -> void:
	var character_id: String = str(contact_option.get_selected_metadata())
	var event_type: Dictionary = type_option.get_selected_metadata()
	var day: Dictionary = day_option.get_selected_metadata()
	var block: String = str(block_option.get_selected_metadata())
	var title: String = str(event_type.get("name", "Plan"))
	if not character_id.is_empty():
		title = "%s with %s" % [title, _character_name(character_id)]
	var result: Dictionary = SimulationService.apply_operation(
		"calendar.schedule",
		{
			"calendar_event": {
				"title": title,
				"type": event_type.get("id", "personal"),
				"date": "Y%d-%02d-%02d" % [day["year"], day["month"], day["day"]],
				"weekday": day["weekday"],
				"block": block,
				"participants": [] if character_id.is_empty() else [character_id],
				"location": event_type.get("default_location", "hale_home.player_bedroom"),
				"source": "phone.calendar",
			},
		},
		"phone.calendar"
	)
	if not result.get("ok", false):
		scheduler_status.text = str(result.get("errors", ["The plan could not be scheduled."])[0])
		return
	scheduler_panel.visible = false
	phone_status.text = "%s was added to the calendar." % title
	_show_app("calendar")


func _cancel_calendar_event(event_id: String) -> void:
	var result: Dictionary = SimulationService.apply_operation(
		"calendar.cancel_or_reschedule",
		{"event_id": event_id, "cancel": true},
		"phone.calendar"
	)
	phone_status.text = "Plan cancelled." if result.get("ok", false) else str(result.get("errors", ["Cancellation failed."])[0])
	_render_calendar()


func _on_close_scheduler_pressed() -> void:
	scheduler_panel.visible = false


func _on_close_phone_pressed() -> void:
	close_phone()


func _cycle_text_size() -> void:
	var sizes: Array = [1.0, 1.25, 1.5, 1.75]
	var current: int = sizes.find(SettingsService.text_scale)
	SettingsService.text_scale = sizes[posmod(current + 1, sizes.size())]
	_save_and_refresh_settings()


func _toggle_reduce_motion() -> void:
	SettingsService.reduce_motion = not SettingsService.reduce_motion
	_save_and_refresh_settings()


func _toggle_high_contrast() -> void:
	SettingsService.high_contrast = not SettingsService.high_contrast
	_save_and_refresh_settings()


func _adjust_master_volume(amount: float) -> void:
	SettingsService.master_volume = clampf(SettingsService.master_volume + amount, 0.0, 1.0)
	SettingsService.apply_audio_settings()
	_save_and_refresh_settings()


func _save_and_refresh_settings() -> void:
	var error: Error = SettingsService.save_settings()
	phone_status.text = "Settings saved." if error == OK else "Settings could not be saved."
	_render_settings()


func _add_action_button(label: String, callback: Callable) -> void:
	var button: Button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 39)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	app_actions.add_child(button)


func _availability_now(character: Dictionary) -> String:
	var clock: Dictionary = GameState.current_state["clock"]
	for commitment: Variant in character.get("schedule", {}).get("fixed_commitments", []):
		if commitment is Dictionary and bool(commitment.get("unavailable", false)) and str(clock["weekday"]) in commitment.get("days", []) and str(clock["block"]) in commitment.get("blocks", []):
			return "Busy now: %s" % str(commitment.get("activity", "prior commitment")).replace("_", " ")
	return "No blocking work or school commitment right now"


func _outfit_scores(outfit: Dictionary) -> Dictionary:
	var scores: Dictionary = {"warmth": 0, "rain_protection": 0, "wind_protection": 0}
	for item_id: Variant in outfit.values():
		var item: Variant = ContentRegistry.get_content("items", str(item_id))
		if not item is Dictionary:
			continue
		for score: String in scores:
			scores[score] += int(item.get(score, 0))
	return scores


func _format_number_grid(values: Dictionary) -> String:
	var parts: PackedStringArray = []
	var keys: Array = values.keys()
	keys.sort()
	for key: Variant in keys:
		parts.append("%s %d" % [str(key).replace("_", " ").capitalize(), int(values[key])])
	return " • ".join(parts)


func _format_skills(skills: Dictionary) -> String:
	if skills.is_empty():
		return "No developed skills yet. Practice activities to begin progressing."
	return _format_number_grid(skills)


func _format_accounts(accounts: Dictionary) -> String:
	var parts: PackedStringArray = []
	for account: Variant in accounts:
		parts.append("%s $%.2f" % [str(account).replace("_", " ").capitalize(), float(accounts[account])])
	return " • ".join(parts)


func _format_outfit(outfit: Dictionary) -> String:
	var parts: PackedStringArray = []
	for slot: Variant in outfit:
		var item: Variant = ContentRegistry.get_content("items", str(outfit[slot]))
		parts.append("%s: %s" % [str(slot).capitalize(), item.get("name", outfit[slot]) if item is Dictionary else outfit[slot]])
	return "\n".join(parts) if not parts.is_empty() else "Nothing equipped."


func _joined_labels(values: Array) -> String:
	var labels: PackedStringArray = []
	for value: Variant in values:
		labels.append(str(value).replace("_", " ").capitalize())
	return ", ".join(labels) if not labels.is_empty() else "None selected"


func _quest_names(ids: Array) -> String:
	var names: PackedStringArray = []
	for quest_id: Variant in ids:
		var quest: Variant = ContentRegistry.get_content("quests", str(quest_id))
		names.append(str(quest.get("title", quest_id)) if quest is Dictionary else str(quest_id))
	return ", ".join(names)


func _meter_level(value: int) -> String:
	var result: String = "New"
	for level: Variant in ContentRegistry.get_package("port_alder_phone_system").get("relationship_levels", []):
		if level is Dictionary and value >= int(level.get("minimum", 0)):
			result = "Level %d: %s" % [level.get("level", 1), level.get("name", "New")]
	return result


func _message_definition(character_id: String, message_id: String) -> Dictionary:
	var character: Dictionary = ContentRegistry.get_character(character_id)
	for definition: Variant in character.get("text_messages", []):
		if definition is Dictionary and str(definition.get("id", "")) == message_id:
			return definition
	return {}


func _thread_has_reply(thread: Dictionary, message_id: String) -> bool:
	for message: Variant in thread.get("messages", []):
		if message is Dictionary and str(message.get("reply_to", "")) == message_id:
			return true
	return false


func _friendly_timestamp(timestamp: String) -> String:
	return timestamp.trim_prefix("Y").replace(":", " • ").replace("+", " +").replace("_", " ")


func _character_name(character_id: String) -> String:
	var character: Variant = ContentRegistry.get_character(character_id)
	return str(character.get("display_name", character_id)) if character is Dictionary else character_id


func _location_name(destination: String) -> String:
	var location_id: String = destination.get_slice(".", 0)
	var location: Variant = ContentRegistry.get_location(location_id)
	var name: String = str(location.get("name", location_id)) if location is Dictionary else location_id
	return "%s — %s" % [name, destination.get_slice(".", 1).replace("_", " ").capitalize()] if destination.contains(".") else name


func _short_location_name(location_id: String) -> String:
	var location: Variant = ContentRegistry.get_location(location_id)
	return str(location.get("name", location_id)) if location is Dictionary else location_id.replace("_", " ").capitalize()


func _date_after_days(clock: Dictionary, offset: int) -> Dictionary:
	var year: int = int(clock["year"])
	var month: int = int(clock["month"])
	var day: int = int(clock["day"])
	for _step: int in offset:
		day += 1
		if day > _days_in_month(month, year):
			day = 1
			month += 1
			if month > 12:
				month = 1
				year += 1
	var weekday_index: int = posmod(WEEKDAYS.find(str(clock["weekday"])) + offset, WEEKDAYS.size())
	return {"year": year, "month": month, "day": day, "weekday": WEEKDAYS[weekday_index]}


func _days_in_month(month: int, year: int) -> int:
	if month in [4, 6, 9, 11]:
		return 30
	if month == 2:
		return 29 if year % 4 == 0 else 28
	return 31


func _on_off(value: bool) -> String:
	return "On" if value else "Off"


func _clear_container(container: Container) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
