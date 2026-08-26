extends Control

signal phone_opened
signal phone_closed
signal travel_completed(destination: String)

const APP_ORDER: PackedStringArray = [
	"character_profile", "contacts", "messages", "calendar", "education", "jobs", "money", "shopping", "quests",
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
var _selected_relationship_contact: String = ""
var _selected_route_destination: String = ""
var _job_filter: String = "all"
var _selected_job_id: String = ""
var _interview_job_id: String = ""
var _interview_question_index: int = 0
var _interview_answer_quality: int = 0
var _selected_store_id: String = ""
var _pending_manual_overwrite: String = ""
var _pending_remap_action: String = ""


func _ready() -> void:
	_build_app_buttons()
	SettingsService.settings_changed.connect(_apply_accessibility_settings)
	_apply_accessibility_settings()
	visible = false


func _input(event: InputEvent) -> void:
	if not visible or _pending_remap_action.is_empty():
		return
	if event is InputEventKey and not event.pressed:
		return
	if event is InputEventJoypadButton and not event.pressed:
		return
	if event is InputEventJoypadMotion and absf(event.axis_value) < 0.5:
		return
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	var action: String = _pending_remap_action
	_pending_remap_action = ""
	if SettingsService.remap_action(action, event):
		var error: Error = SettingsService.save_settings()
		phone_status.text = "%s is now %s." % [SettingsService.action_name(action), SettingsService.binding_label(action)] if error == OK else "The new binding could not be saved."
	else:
		phone_status.text = "That input cannot be used for this action."
	_render_settings()
	get_viewport().set_input_as_handled()


func open_phone(default_app: String = "character_profile") -> void:
	if not GameState.has_active_game():
		return
	PhoneService.sync_messages()
	RelationshipService.sync_dates()
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
	_pending_remap_action = ""
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
		"education":
			_render_education()
		"jobs":
			_render_jobs()
		"money":
			_render_money()
		"shopping":
			_render_shopping()
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
		var required_type: bool = bool(calendar_event.get("required", false)) or str(calendar_event.get("type", "")) in ["class", "exam", "work", "interview"]
		if status == "scheduled" and not required_type and str(calendar_event.get("source", "")) != "opening_future_talk":
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
	_clear_container(app_actions)
	app_title.text = "QUESTS"
	var state: Dictionary = GameState.current_state
	var tracked: Array = state["quest_state"].get("tracked", [])
	var lines: PackedStringArray = [
		"[color=#a9bdd0]Quests are discovered through play. Open-ended quests do not expire merely because time passes.[/color]",
		"ACTIVE",
	]
	for quest_id_value: Variant in state["quest_state"].get("active", []):
		var quest_id: String = str(quest_id_value)
		var quest: Dictionary = ContentRegistry.get_content("quests", quest_id)
		var tracking_label: String = " [color=#e9a86c]• TRACKED[/color]" if quest_id in tracked else ""
		lines.append("[font_size=21]%s[/font_size]%s\n%s" % [quest.get("title", quest_id), tracking_label, quest.get("summary", "")])
		var timing: Variant = quest.get("timing")
		if timing is Dictionary:
			lines.append("[color=#efc46e]TIME-SENSITIVE • %s[/color]" % timing.get("reason", "This opportunity has an authored deadline."))
		for objective: Variant in QuestService.get_progress(quest_id).get("objectives", []):
			if objective is Dictionary:
				lines.append("%s %s" % ["✓" if objective.get("completed", false) else "○", objective.get("text", objective.get("id", "Objective"))])
		_add_action_button(
			"Untrack %s" % quest.get("title", quest_id) if quest_id in tracked else "Track %s" % quest.get("title", quest_id),
			_set_quest_tracking.bind(quest_id, quest_id not in tracked)
		)
	for section: String in ["completed", "deferred", "failed"]:
		lines.append("\n%s" % section.to_upper())
		var ids: Array = state["quest_state"].get(section, [])
		lines.append(_quest_names(ids) if not ids.is_empty() else "None")
	app_content.text = "\n".join(lines)


func _set_quest_tracking(quest_id: String, tracked: bool) -> void:
	var result: Dictionary = QuestService.set_tracked(quest_id, tracked)
	phone_status.text = "Quest tracker updated." if result.get("ok", false) else str(result.get("errors", ["Quest tracking could not be updated."])[0])
	_render_quests()


func _render_education() -> void:
	_clear_container(app_actions)
	app_title.text = "EDUCATION"
	var sync_result: Dictionary = EducationService.sync_education()
	if not sync_result.get("ok", false):
		phone_status.text = str(sync_result.get("errors", ["Education records could not be synchronized."])[0])
		app_content.text = "Education records are unavailable."
		return
	if not sync_result.get("data", {}).get("notices", []).is_empty():
		phone_status.text = " • ".join(sync_result["data"]["notices"])
	var education: Dictionary = GameState.current_state["player"]["education"]
	if not bool(education.get("enrolled", false)):
		app_content.text = "You are not currently enrolled. Visit Westshore Administration while the enrollment quest is active to choose a program and course load."
		return
	var program: Variant = ContentRegistry.get_content("programs", str(education.get("program", "")))
	var semester: Dictionary = education.get("semester", {})
	var lines: PackedStringArray = [
		"[font_size=23]WESTSHORE COLLEGE[/font_size]",
		"%s • %s" % [program.get("name", education.get("program", "Program")) if program is Dictionary else str(education.get("program", "Program")).replace("_", " ").capitalize(), str(education.get("course_load", education.get("load", ""))).replace("_", " ").capitalize()],
		"Semester %d • %s" % [education.get("semester_number", 1), str(semester.get("phase", "pre_orientation")).replace("_", " ").capitalize()],
		"Standing: [color=#e9a86c]%s[/color] • Credits earned: %d" % [str(education.get("academic_standing", "good_standing")).replace("_", " ").capitalize(), education.get("credits_earned", 0)],
	]
	if bool(education.get("registration_hold", false)):
		lines.append("[color=#ef7777]Registration hold: an advisor review is required before the next semester.[/color]")
	var class_status: Dictionary = EducationService.class_status()
	var class_event: Dictionary = class_status.get("event", {})
	var next_class: Dictionary = class_status.get("next_event", {})
	lines.append("\n[font_size=23]CLASS STATUS[/font_size]")
	if not class_event.is_empty():
		lines.append("%s • %s\n%s" % [class_event.get("title", "Class"), _location_name(str(class_event.get("location", ""))), class_status.get("reason", "Ready to attend now.")])
	elif not next_class.is_empty():
		lines.append("Next: %s\n%s • %s • %s" % [next_class.get("title", "Class"), next_class.get("date", ""), str(next_class.get("block", "")).replace("_", " ").capitalize(), _location_name(str(next_class.get("location", "")))])
	else:
		lines.append(str(class_status.get("reason", "No classes are currently scheduled.")))
	if bool(class_status.get("ready", false)):
		for approach_id: String in ["balanced", "engaged", "quiet_notes"]:
			_add_action_button("Attend Class — %s" % approach_id.replace("_", " ").capitalize(), _attend_education_class.bind(approach_id))
	lines.append("\n[font_size=23]COURSES AND GRADES[/font_size]")
	for course_id_value: Variant in education.get("courses", []):
		var course_id: String = str(course_id_value)
		var course: Variant = ContentRegistry.get_content("courses", course_id)
		var grade: Dictionary = education.get("grades", {}).get(course_id, {})
		var attendance: Dictionary = education.get("attendance", {}).get(course_id, {})
		lines.append("[font_size=20]%s[/font_size]\n%.1f%% • %s • %s\nAttendance %d present / %d late / %d absent • Preparation %.0f" % [
			course.get("name", course_id) if course is Dictionary else course_id,
			float(grade.get("current_percent", 0.0)), grade.get("letter_grade", "—"), str(grade.get("status", "not_started")).replace("_", " ").capitalize(),
			attendance.get("attended", 0), attendance.get("late", 0), attendance.get("absent", 0), float(education.get("course_preparation", {}).get(course_id, 0.0)),
		])
		_add_action_button("Study %s — 90 min" % (course.get("name", course_id) if course is Dictionary else course_id), _study_education_course.bind(course_id, "standard"))
		_add_action_button("Study Thoroughly — %s — 3 hr" % (course.get("name", course_id) if course is Dictionary else course_id), _study_education_course.bind(course_id, "thorough"))
	lines.append("\n[font_size=23]UPCOMING COURSEWORK[/font_size]")
	var upcoming: Array = EducationService.upcoming_assessments(8)
	if upcoming.is_empty():
		lines.append("No unresolved assessments.")
	var today_value: int = _phone_date_value("Y%d-%02d-%02d" % [GameState.current_state["clock"]["year"], GameState.current_state["clock"]["month"], GameState.current_state["clock"]["day"]])
	for assessment_value: Variant in upcoming:
		if not assessment_value is Dictionary:
			continue
		var assessment: Dictionary = assessment_value
		var assessment_type: String = str(assessment.get("type", "assignment"))
		lines.append("%s\n%s • %s • Opens %s" % [assessment.get("title", assessment.get("id", "Assessment")), assessment.get("due_date", ""), str(assessment.get("block", "")).replace("_", " ").capitalize(), assessment.get("available_date", "")])
		var available_now: bool = today_value >= _phone_date_value(str(assessment.get("available_date", assessment.get("due_date", "")))) and today_value <= _phone_date_value(str(assessment.get("due_date", "")))
		if assessment_type in ["midterm", "final"]:
			var clock: Dictionary = GameState.current_state["clock"]
			if available_now and str(assessment.get("due_date", "")) == "Y%d-%02d-%02d" % [clock["year"], clock["month"], clock["day"]] and str(assessment.get("block", "")) == str(clock["block"]):
				_add_action_button("Take %s" % assessment.get("title", "Exam"), _complete_education_assessment.bind(str(assessment.get("id", "")), "exam"))
		elif available_now:
			_add_action_button("Complete Standard — %s" % assessment.get("title", "Coursework"), _complete_education_assessment.bind(str(assessment.get("id", "")), "standard"))
			_add_action_button("Complete Thoroughly — %s" % assessment.get("title", "Coursework"), _complete_education_assessment.bind(str(assessment.get("id", "")), "thorough"))
	app_content.text = "\n\n".join(lines)


func _attend_education_class(approach_id: String) -> void:
	var result: Dictionary = EducationService.attend_class(approach_id)
	if result.get("ok", false):
		var record: Dictionary = result.get("data", {}).get("record", {})
		phone_status.text = "%s recorded with %.1f performance." % [str(record.get("status", "present")).capitalize(), float(record.get("performance", 0.0))]
	else:
		phone_status.text = str(result.get("errors", ["Class attendance failed."])[0])
	_render_education()


func _study_education_course(course_id: String, effort_id: String) -> void:
	var result: Dictionary = EducationService.study_course(course_id, effort_id)
	phone_status.text = "Study completed; preparation increased by %.0f." % float(result.get("data", {}).get("preparation_gain", 0.0)) if result.get("ok", false) else str(result.get("errors", ["Study session failed."])[0])
	_render_education()


func _complete_education_assessment(assessment_id: String, effort_id: String) -> void:
	var result: Dictionary = EducationService.complete_assessment(assessment_id, effort_id)
	phone_status.text = "%s submitted with a %.1f%% score." % [result.get("data", {}).get("assessment", {}).get("title", "Assessment"), result.get("data", {}).get("result", {}).get("score", 0.0)] if result.get("ok", false) else str(result.get("errors", ["Assessment could not be completed."])[0])
	_render_education()


func _render_jobs() -> void:
	_clear_container(app_actions)
	if not _interview_job_id.is_empty():
		_render_interview_question()
		return
	var sync_result: Dictionary = EmploymentService.sync_employment()
	if not sync_result.get("ok", false):
		phone_status.text = str(sync_result.get("errors", ["Employment records could not be synchronized."])[0])
	elif not sync_result.get("data", {}).get("notices", []).is_empty():
		phone_status.text = " • ".join(sync_result["data"]["notices"])
	app_title.text = "JOBS"
	if not _selected_job_id.is_empty():
		_render_job_detail(_selected_job_id)
		return
	EmploymentService.record_listings_viewed(_job_filter)
	var listings: Array = EmploymentService.get_listings(_job_filter)
	var employment: Dictionary = GameState.current_state["player"]["employment"]
	var lines: PackedStringArray = [
		"Search filter: [color=#e9a86c]%s[/color]" % _job_filter.replace("_", " ").capitalize(),
		"Applications: %d • Active jobs: %d" % [employment.get("applications", []).size(), employment.get("active_jobs", []).size()],
		"Qualified means every authored skill, trait, education, attribute, health, and licensing requirement is currently met.",
	]
	for active_job_value: Variant in employment.get("active_jobs", []):
		if not active_job_value is Dictionary or str(active_job_value.get("status", "active")) != "active":
			continue
		var active_job: Dictionary = active_job_value
		var pending: Dictionary = active_job.get("pending_pay", {})
		var shift_status: Dictionary = EmploymentService.shift_status(str(active_job.get("job_id", "")))
		lines.append("[font_size=21]%s[/font_size]\n%s • $%.2f/hour • Performance %.0f\nPending gross: $%.2f • %s\n%s" % [
			active_job.get("title", active_job.get("job_id", "Job")), active_job.get("employer", ""),
			float(active_job.get("hourly_pay", 0.0)), float(active_job.get("performance", 50.0)),
			float(pending.get("gross_wages", 0.0)) + float(pending.get("tips", 0.0)),
			active_job.get("next_payday", "No payday scheduled"), shift_status.get("reason", ""),
		])
	for entry: Variant in listings:
		if not entry is Dictionary:
			continue
		var job: Dictionary = entry["job"]
		var qualification: Dictionary = entry["qualification"]
		var application: Dictionary = entry["application"]
		var pay: String = "$%.2f/hour" % float(job.get("hourly_pay", 0.0))
		if job.has("booking_pay_range"):
			pay = "$%d–$%d/booking" % [job["booking_pay_range"][0], job["booking_pay_range"][1]]
		var status: String = "Qualified" if bool(qualification["qualified"]) else "%d%% match" % qualification["match_percent"]
		if not application.is_empty():
			status = str(application.get("stage", "applied")).replace("_", " ").capitalize()
		lines.append("[font_size=20]%s[/font_size]\n%s • %s\n%s • %s" % [
			job.get("title", job.get("id", "Job")), job.get("employer", ""), pay,
			_joined_labels(job.get("employment_types", [])), status,
		])
		_add_action_button("View %s" % job.get("title", job.get("id", "job")), _open_job_detail.bind(str(job.get("id", ""))))
	app_content.text = "\n\n".join(lines) if not listings.is_empty() else "No listings match this filter."
	for filter_id: String in ["all", "qualified", "part_time", "full_time"]:
		_add_action_button("Filter: %s%s" % [filter_id.replace("_", " ").capitalize(), " ✓" if filter_id == _job_filter else ""], _set_job_filter.bind(filter_id))
	_add_action_button("Save Availability Around Calendar", _save_job_availability)


func _render_job_detail(job_id: String) -> void:
	var job: Variant = ContentRegistry.get_content("jobs", job_id)
	if not job is Dictionary:
		_selected_job_id = ""
		_render_jobs()
		return
	app_title.text = str(job.get("title", job_id)).to_upper()
	var qualification: Dictionary = EmploymentService.qualification_report(job_id)
	var application: Dictionary = _employment_application(job_id)
	var active_job: Dictionary = _active_employment_job(job_id)
	var lines: PackedStringArray = [
		"[font_size=23]%s[/font_size]" % job.get("employer", ""),
		"Location: %s" % _location_name(str(job.get("location", ""))),
		"Type: %s" % _joined_labels(job.get("employment_types", [])),
	]
	if job.has("hourly_pay"):
		lines.append("Pay: $%.2f per hour" % float(active_job.get("hourly_pay", job.get("hourly_pay", 0.0))))
	elif job.has("booking_pay_range"):
		lines.append("Pay: $%d–$%d per booking" % [job["booking_pay_range"][0], job["booking_pay_range"][1]])
	lines.append("\nREQUIREMENTS — %s" % ("[color=#67c6c3]MET[/color]" if qualification.get("qualified", false) else "[color=#ef7777]NOT MET[/color]"))
	for requirement: Variant in qualification.get("met", []):
		lines.append("✓ %s" % requirement)
	for requirement: Variant in qualification.get("missing", []):
		lines.append("[color=#ef7777]○ %s[/color]" % requirement)
	lines.append("\nSCHEDULE OPTIONS")
	for schedule: Variant in job.get("schedule_options", []):
		if schedule is Dictionary:
			lines.append("%s — %s hours\n%s • %s" % [
				str(schedule.get("id", "schedule")).replace("_", " ").capitalize(),
				schedule.get("weekly_hours", "Variable"),
				_joined_labels(schedule.get("days", [])),
				_joined_labels(schedule.get("blocks", [])),
			])
	if not active_job.is_empty():
		var pending: Dictionary = active_job.get("pending_pay", {})
		var shift_status: Dictionary = EmploymentService.shift_status(job_id)
		var review_status: Dictionary = EmploymentService.career_review_status(job_id)
		lines.append("\nACTIVE EMPLOYMENT")
		lines.append("Current title: [color=#67c6c3]%s[/color]" % active_job.get("title", job.get("title", job_id)))
		lines.append("Performance: %.1f/100 • Career level %d" % [float(active_job.get("performance", 50.0)), int(active_job.get("career_level", 0))])
		lines.append("Shifts completed: %d • Late: %d • Missed: %d" % [active_job.get("shifts_completed", 0), active_job.get("late_shifts", 0), active_job.get("shifts_missed", 0)])
		lines.append("Hours worked: %.2f • Lifetime net: $%.2f" % [float(active_job.get("hours_worked_total", 0.0)), float(active_job.get("lifetime_net", 0.0))])
		lines.append("Pending pay: %.2f hours • $%.2f gross/tips" % [float(pending.get("hours", 0.0)), float(pending.get("gross_wages", 0.0)) + float(pending.get("tips", 0.0))])
		var latest_payroll: Dictionary = _latest_payroll_record(job_id)
		if not latest_payroll.is_empty():
			lines.append("Last paycheck: $%.2f net ($%.2f wages + $%.2f tips − $%.2f withholding)" % [
				float(latest_payroll.get("net", 0.0)), float(latest_payroll.get("gross", 0.0)),
				float(latest_payroll.get("tips", 0.0)), float(latest_payroll.get("withholding", 0.0)),
			])
		lines.append("Next payday: %s • %s" % [active_job.get("next_payday", "Unscheduled"), review_status.get("reason", "")])
		lines.append("Next shift: %s" % shift_status.get("reason", "No scheduled shift."))
		var pending_promotion: Variant = active_job.get("pending_promotion")
		if pending_promotion is Dictionary:
			lines.append("[color=#e9a86c]Promotion opening: %s[/color]" % pending_promotion.get("title", "New role"))
		elif review_status.get("promotion", {}).get("available", false):
			lines.append("Next promotion: %s — %s" % [review_status["promotion"].get("step", {}).get("title", "New role"), review_status["promotion"].get("reason", "")])
	if application.is_empty():
		lines.append("\nAPPLICATION\nNo application submitted.")
	else:
		var stage: String = str(application.get("stage", "submitted"))
		lines.append("\nAPPLICATION\nStatus: [color=#e9a86c]%s[/color]" % stage.replace("_", " ").capitalize())
		if stage == "interview_scheduled":
			var readiness: Dictionary = EmploymentService.interview_ready(job_id)
			lines.append(str(readiness.get("reason", "Interview scheduled.")))
		elif stage in ["offer_received", "rejected", "waitlisted"]:
			lines.append("Interview score: %d • %s" % [int(application.get("interview_score", 0)), str(application.get("interview_outcome", stage)).replace("_", " ").capitalize()])
	app_content.text = "\n".join(lines)
	_add_action_button("← All Listings", _close_job_detail)
	if not active_job.is_empty():
		var active_shift_status: Dictionary = EmploymentService.shift_status(job_id)
		if bool(active_shift_status.get("ready", false)):
			for approach: Variant in ContentRegistry.get_package("port_alder_employment_system").get("employment_rules", {}).get("work_approaches", []):
				if approach is Dictionary:
					_add_action_button("Clock In — %s" % approach.get("name", approach.get("id", "Work")), _perform_job_shift.bind(job_id, str(approach.get("id", "steady"))))
		var active_review_status: Dictionary = EmploymentService.career_review_status(job_id)
		if bool(active_review_status.get("due", false)):
			_add_action_button("Complete 90-Day Career Review", _process_job_review.bind(job_id))
		if active_job.get("pending_promotion") is Dictionary:
			_add_action_button("Accept Promotion — %s" % active_job["pending_promotion"].get("title", "New Role"), _accept_job_promotion.bind(job_id))
	if application.is_empty() and bool(qualification.get("qualified", false)):
		for employment_type: Variant in job.get("employment_types", []):
			var type_id: String = str(employment_type)
			if type_id not in ["part_time", "full_time"]:
				continue
			if EmploymentService.compatible_schedules(job_id, type_id).is_empty():
				continue
			_add_action_button("Apply — %s" % type_id.replace("_", " ").capitalize(), _apply_to_job.bind(job_id, type_id))
	elif not application.is_empty() and str(application.get("stage", "")) == "interview_scheduled":
		var readiness: Dictionary = EmploymentService.interview_ready(job_id)
		if bool(readiness.get("ready", false)):
			_add_action_button("Start Video Interview", _begin_job_interview.bind(job_id))
	elif not application.is_empty() and str(application.get("stage", "")) == "offer_received":
		for schedule: Variant in EmploymentService.compatible_schedules(job_id, str(application.get("requested_type", "all"))):
			if not schedule is Dictionary or str(schedule.get("id", "")) not in application.get("offer", {}).get("eligible_schedule_ids", []):
				continue
			_add_action_button("Accept Offer — %s (%s hrs/week)" % [str(schedule.get("id", "")).replace("_", " ").capitalize(), schedule.get("weekly_hours", 0)], _accept_job_offer.bind(job_id, str(schedule.get("id", ""))))


func _open_job_detail(job_id: String) -> void:
	_selected_job_id = job_id
	_render_jobs()


func _close_job_detail() -> void:
	_selected_job_id = ""
	_render_jobs()


func _set_job_filter(filter_id: String) -> void:
	_job_filter = filter_id
	_selected_job_id = ""
	_render_jobs()


func _save_job_availability() -> void:
	var result: Dictionary = EmploymentService.save_availability()
	phone_status.text = "Work availability saved around required classes and shifts." if result.get("ok", false) else str(result.get("errors", ["Availability could not be saved."])[0])
	_render_jobs()


func _apply_to_job(job_id: String, requested_type: String) -> void:
	var result: Dictionary = EmploymentService.apply_to_job(job_id, requested_type)
	if result.get("ok", false):
		var application: Dictionary = result.get("data", {}).get("application", {})
		var interview_id: String = str(application.get("interview_id", ""))
		var interview: Dictionary = _employment_record_by_id(GameState.current_state["player"]["employment"].get("interviews", []), interview_id)
		phone_status.text = "Application submitted. Video interview: %s • %s." % [interview.get("date", ""), str(interview.get("block", "")).replace("_", " ").capitalize()]
	else:
		phone_status.text = str(result.get("errors", ["Application could not be submitted."])[0])
	_render_jobs()


func _begin_job_interview(job_id: String) -> void:
	var readiness: Dictionary = EmploymentService.interview_ready(job_id)
	if not bool(readiness.get("ready", false)):
		phone_status.text = str(readiness.get("reason", "The interview is not ready."))
		return
	_interview_job_id = job_id
	_interview_question_index = 0
	_interview_answer_quality = 0
	_render_jobs()


func _render_interview_question() -> void:
	_clear_container(app_actions)
	var job: Dictionary = ContentRegistry.get_content("jobs", _interview_job_id)
	var questions: Array = _interview_questions()
	if _interview_question_index >= questions.size():
		_finish_job_interview()
		return
	var question: Dictionary = questions[_interview_question_index]
	app_title.text = "INTERVIEW • %d/%d" % [_interview_question_index + 1, questions.size()]
	app_content.text = "[font_size=23]%s[/font_size]\n%s\n\n%s" % [
		job.get("title", _interview_job_id), job.get("employer", ""), question.get("prompt", ""),
	]
	for answer: Variant in question.get("answers", []):
		if answer is Dictionary:
			_add_action_button(str(answer.get("text", "Answer")), _answer_interview_question.bind(int(answer.get("score", 0))))


func _answer_interview_question(score: int) -> void:
	_interview_answer_quality += score
	_interview_question_index += 1
	_render_jobs()


func _finish_job_interview() -> void:
	var job_id: String = _interview_job_id
	var result: Dictionary = EmploymentService.complete_interview(job_id, mini(_interview_answer_quality, 20))
	_interview_job_id = ""
	_interview_question_index = 0
	_interview_answer_quality = 0
	_selected_job_id = job_id
	if result.get("ok", false):
		var data: Dictionary = result.get("data", {})
		phone_status.text = "Interview complete: %d/100 — %s." % [data.get("score", 0), str(data.get("outcome", "result")).replace("_", " ").capitalize()]
	else:
		phone_status.text = str(result.get("errors", ["Interview could not be completed."])[0])
	_render_jobs()


func _accept_job_offer(job_id: String, schedule_id: String) -> void:
	var result: Dictionary = EmploymentService.accept_offer(job_id, schedule_id)
	phone_status.text = "Offer accepted. Your first six weeks of shifts are on the Calendar." if result.get("ok", false) else str(result.get("errors", ["Offer could not be accepted."])[0])
	_render_jobs()


func _perform_job_shift(job_id: String, approach_id: String) -> void:
	var result: Dictionary = EmploymentService.perform_shift(job_id, approach_id)
	if result.get("ok", false):
		var shift: Dictionary = result.get("data", {}).get("shift", {})
		phone_status.text = "Shift complete: %.2f hours, $%.2f wages, performance %.1f." % [
			float(shift.get("hours_worked", 0.0)), float(shift.get("gross_wages", 0.0)) + float(shift.get("tips", 0.0)), float(shift.get("performance_after", 0.0)),
		]
	else:
		phone_status.text = str(result.get("errors", ["The shift could not be completed."])[0])
	_render_jobs()


func _process_job_review(job_id: String) -> void:
	var result: Dictionary = EmploymentService.process_career_review(job_id)
	if result.get("ok", false):
		var review: Dictionary = result.get("data", {}).get("review", {})
		var raise_text: String = "%d%% raise" % int(review.get("raise_percent", 0)) if int(review.get("raise_percent", 0)) > 0 else "no raise"
		phone_status.text = "Career review complete: %s%s." % [raise_text, " and a promotion opening" if review.get("promotion_opening", false) else ""]
	else:
		phone_status.text = str(result.get("errors", ["The career review could not be completed."])[0])
	_render_jobs()


func _accept_job_promotion(job_id: String) -> void:
	var result: Dictionary = EmploymentService.accept_promotion(job_id)
	phone_status.text = "Promotion accepted: %s at $%.2f/hour." % [result.get("data", {}).get("title", "New role"), result.get("data", {}).get("hourly_pay", 0.0)] if result.get("ok", false) else str(result.get("errors", ["The promotion could not be accepted."])[0])
	_render_jobs()


func _interview_questions() -> Array:
	return [
		{"prompt": "Why do you want this position?", "answers": [
			{"text": "Connect the role to your strengths and the employer's needs.", "score": 7},
			{"text": "Give an honest, general reason for needing work.", "score": 5},
			{"text": "Say you mainly care about the pay.", "score": 2},
		]},
		{"prompt": "Tell us about a time you were reliable.", "answers": [
			{"text": "Give a specific example, action, and result.", "score": 7},
			{"text": "Describe your usual approach without an example.", "score": 5},
			{"text": "Say people should simply trust you.", "score": 1},
		]},
		{"prompt": "How would you handle a schedule conflict?", "answers": [
			{"text": "Raise it early, propose coverage, and confirm the solution.", "score": 6},
			{"text": "Tell the manager as soon as you notice it.", "score": 4},
			{"text": "Wait and see whether it becomes a problem.", "score": 0},
		]},
	]


func _render_money() -> void:
	_clear_container(app_actions)
	var sync_result: Dictionary = EconomyService.sync_economy()
	if not sync_result.get("ok", false):
		phone_status.text = str(sync_result.get("errors", ["The economy could not be synchronized."])[0])
	elif not sync_result.get("data", {}).get("notices", []).is_empty():
		phone_status.text = " • ".join(sync_result["data"]["notices"])
	app_title.text = "MONEY"
	var player: Dictionary = GameState.current_state["player"]
	var economy: Dictionary = player["economy"]
	var education: Dictionary = player["education"]
	var housing: Dictionary = player["housing"]
	var accounts: Dictionary = economy.get("accounts", {})
	var card_debt: float = maxf(0.0, -float(accounts.get("credit_card", 0.0)))
	var summary: Dictionary = EconomyService.current_budget_summary()
	var lines: PackedStringArray = [
		"[font_size=23]ACCOUNTS[/font_size]",
		"Cash $%.2f • Checking $%.2f • Savings $%.2f" % [accounts.get("wallet_cash", 0.0), accounts.get("checking", 0.0), accounts.get("savings", 0.0)],
		"Credit card balance $%.2f • Credit score %d" % [card_debt, economy.get("credit_score", 650)],
		"",
		"[font_size=23]CURRENT WEEK[/font_size]",
		"%s through %s" % [summary.get("start_date", ""), summary.get("end_date", "")],
		"Employment net $%.2f • Allowance $%.2f • Spending $%.2f" % [summary.get("net_income", 0.0), summary.get("allowance", 0.0), summary.get("total_spending", 0.0)],
		"Net account balance $%.2f" % summary.get("ending_balance", 0.0),
		"",
		"[font_size=23]OBLIGATIONS[/font_size]",
		"Tuition: %s • Charge $%.2f • Balance $%.2f" % [str(education.get("tuition_plan", "not arranged")).replace("_", " ").capitalize(), education.get("tuition_charge", 0.0), education.get("tuition_balance", 0.0)],
		"Household rent: $%.2f/month • Outstanding $%.2f" % [housing.get("monthly_rent", 0.0), housing.get("rent_balance", 0.0)],
		"Student debt: $%.2f" % education.get("student_debt", 0.0),
		"",
		"[font_size=23]RECENT LEDGER[/font_size]",
	]
	var ledger: Array = economy.get("ledger", [])
	if ledger.is_empty():
		lines.append("No transactions yet.")
	else:
		for index: int in range(ledger.size() - 1, maxi(-1, ledger.size() - 9), -1):
			var entry: Dictionary = ledger[index]
			lines.append("%s • %s\n%s$%.2f • %s" % [entry.get("date", ""), str(entry.get("account", "")).replace("_", " ").capitalize(), "+" if float(entry.get("amount", 0.0)) >= 0.0 else "", float(entry.get("amount", 0.0)), entry.get("description", "Transaction")])
	if not economy.get("receipts", []).is_empty():
		var receipt: Dictionary = economy["receipts"][-1]
		lines.append("\nLatest receipt: %s • $%.2f • %s" % [receipt.get("store_name", "Store"), receipt.get("total", 0.0), receipt.get("date", "")])
	app_content.text = "\n".join(lines)
	var tuition_balance: float = float(education.get("tuition_balance", 0.0))
	if tuition_balance > 0.0:
		_add_action_button("Pay $100 Toward Tuition", _pay_tuition.bind(100.0))
		_add_action_button("Pay Remaining Tuition — $%.2f" % tuition_balance, _pay_tuition.bind(tuition_balance))
	var rent_balance: float = float(housing.get("rent_balance", 0.0))
	if rent_balance > 0.0:
		_add_action_button("Pay Outstanding Rent — $%.2f" % rent_balance, _pay_rent)
	if card_debt > 0.0:
		_add_action_button("Pay $25 Toward Credit Card", _pay_credit_card.bind(minf(25.0, card_debt)))
		_add_action_button("Pay Credit Card in Full — $%.2f" % card_debt, _pay_credit_card.bind(card_debt))
	if "shopping" in player["phone"].get("unlocked_apps", []):
		_add_action_button("Open Shopping", _show_app.bind("shopping"))


func _pay_tuition(amount: float) -> void:
	var result: Dictionary = EconomyService.pay_tuition(amount)
	phone_status.text = "Tuition payment of $%.2f completed. Remaining: $%.2f." % [result.get("data", {}).get("amount", 0.0), result.get("data", {}).get("balance", 0.0)] if result.get("ok", false) else str(result.get("errors", ["Tuition payment failed."])[0])
	_render_money()


func _pay_rent() -> void:
	var result: Dictionary = EconomyService.pay_outstanding_rent()
	phone_status.text = "Outstanding rent of $%.2f was paid." % result.get("data", {}).get("amount", 0.0) if result.get("ok", false) else str(result.get("errors", ["Rent payment failed."])[0])
	_render_money()


func _pay_credit_card(amount: float) -> void:
	var result: Dictionary = EconomyService.pay_credit_card(amount)
	phone_status.text = "Credit-card payment of $%.2f completed. Remaining: $%.2f." % [result.get("data", {}).get("amount", 0.0), result.get("data", {}).get("remaining", 0.0)] if result.get("ok", false) else str(result.get("errors", ["Credit-card payment failed."])[0])
	_render_money()


func _render_shopping() -> void:
	_clear_container(app_actions)
	app_title.text = "SHOPPING"
	if not _selected_store_id.is_empty():
		_render_store(_selected_store_id)
		return
	var lines: PackedStringArray = ["Browse Port Alder stores. Purchases are delivered to the appropriate home storage container."]
	for entry: Variant in EconomyService.list_stores():
		if not entry is Dictionary:
			continue
		var store: Dictionary = entry.get("store", {})
		lines.append("[font_size=21]%s[/font_size]\n%s • %d items%s" % [
			store.get("name", store.get("id", "Store")), "Open now" if entry.get("open", false) else "Closed now",
			entry.get("item_count", 0), " • %d%% discount" % int(entry.get("discount_percent", 0)) if float(entry.get("discount_percent", 0.0)) > 0.0 else "",
		])
		_add_action_button("Browse %s" % store.get("name", "Store"), _open_store.bind(str(store.get("id", ""))))
	app_content.text = "\n\n".join(lines)


func _render_store(store_id: String) -> void:
	var listing: Dictionary = EconomyService.store_listing(store_id)
	if listing.is_empty():
		_selected_store_id = ""
		_render_shopping()
		return
	var store: Dictionary = listing.get("store", {})
	app_title.text = str(store.get("name", store_id)).to_upper()
	var lines: PackedStringArray = [
		"%s • %s%s" % ["Open now" if listing.get("open", false) else "Closed now", _location_name(str(store.get("location", ""))), " • %d%% discount active" % int(listing.get("discount_percent", 0)) if float(listing.get("discount_percent", 0.0)) > 0.0 else ""],
	]
	for entry: Variant in listing.get("items", []):
		if not entry is Dictionary:
			continue
		var item: Dictionary = entry.get("item", {})
		var quote: Dictionary = entry.get("price", {})
		lines.append("[font_size=20]%s[/font_size]\n%s • $%.2f total (tax $%.2f)" % [item.get("name", item.get("id", "Item")), str(item.get("category", "item")).replace("_", " ").capitalize(), quote.get("total", 0.0), quote.get("tax", 0.0)])
		if listing.get("open", false):
			_add_action_button("Buy %s — $%.2f" % [item.get("name", "Item"), quote.get("total", 0.0)], _purchase_store_item.bind(store_id, str(item.get("id", ""))))
	app_content.text = "\n\n".join(lines)
	_add_action_button("← All Stores", _close_store)


func _open_store(store_id: String) -> void:
	_selected_store_id = store_id
	_render_shopping()


func _close_store() -> void:
	_selected_store_id = ""
	_render_shopping()


func _purchase_store_item(store_id: String, item_id: String) -> void:
	var result: Dictionary = EconomyService.purchase(store_id, item_id, 1)
	if result.get("ok", false):
		var receipt: Dictionary = result.get("data", {}).get("receipt", {})
		phone_status.text = "Purchased %s for $%.2f; receipt saved." % [result.get("data", {}).get("item", {}).get("name", item_id), receipt.get("total", 0.0)]
	else:
		phone_status.text = str(result.get("errors", ["Purchase failed."])[0])
	_render_shopping()


func _render_relationships() -> void:
	_clear_container(app_actions)
	app_title.text = "RELATIONSHIPS"
	if not _selected_relationship_contact.is_empty():
		_render_relationship_detail(_selected_relationship_contact)
		return
	var lines: PackedStringArray = []
	for profile_value: Variant in RelationshipService.candidates():
		if not profile_value is Dictionary:
			continue
		var profile: Dictionary = profile_value
		var character_id: String = str(profile.get("character_id", ""))
		var meters: Dictionary = profile.get("meters", {})
		var agreement: Dictionary = profile.get("agreement", {})
		lines.append("[font_size=22]%s[/font_size]" % _character_name(character_id))
		lines.append("%s • Chapter %d of 5 • %s\nFriendship %d (%s) • Love %d (%s)\nAttraction %d • Lust %d\nTrust %d • Comfort %d • Commitment %d" % [
			str(profile.get("relationship_stage", "acquaintance")).replace("_", " ").capitalize(),
			int(profile.get("chapter_level", 1)),
			str(agreement.get("name", "No dating agreement")) if str(agreement.get("status", "none")) == "active" else "No dating agreement",
			int(meters.get("friendship", 0)), _meter_level(int(meters.get("friendship", 0))),
			int(meters.get("love", 0)), _meter_level(int(meters.get("love", 0))),
			int(meters.get("attraction", 0)), int(meters.get("lust", 0)),
			int(meters.get("trust", 0)), int(meters.get("comfort", 0)), int(meters.get("commitment", 0)),
		])
		_add_action_button("View %s" % _character_name(character_id), _open_relationship_detail.bind(character_id))
	app_content.text = "\n\n".join(lines) if not lines.is_empty() else "Meet people and exchange contact information to track relationships here."


func _render_relationship_detail(character_id: String) -> void:
	var profile: Dictionary = RelationshipService.relationship_profile(character_id)
	if profile.is_empty():
		_selected_relationship_contact = ""
		_render_relationships()
		return
	var meters: Dictionary = profile.get("meters", {})
	var agreement: Dictionary = profile.get("agreement", {})
	var chapter: Dictionary = profile.get("chapter", {})
	var agreement_label: String = "Not discussed"
	if str(agreement.get("status", "none")) == "active":
		agreement_label = str(agreement.get("name", agreement.get("type", "Dating agreement")))
	var lines: PackedStringArray = [
		"[font_size=26]%s[/font_size]" % profile.get("display_name", character_id),
		"%s • %d completed date(s)" % [str(profile.get("relationship_stage", "acquaintance")).replace("_", " ").capitalize(), int(profile.get("completed_dates", 0))],
		"Agreement: [color=#e9a86c]%s[/color]" % agreement_label,
		"",
		"PRIMARY METERS",
		"Friendship %d — %s\nLove %d — %s\nAttraction %d — %s\nLust %d — %s" % [
			int(meters.get("friendship", 0)), _meter_level(int(meters.get("friendship", 0))),
			int(meters.get("love", 0)), _meter_level(int(meters.get("love", 0))),
			int(meters.get("attraction", 0)), _meter_level(int(meters.get("attraction", 0))),
			int(meters.get("lust", 0)), _meter_level(int(meters.get("lust", 0))),
		],
		"",
		"RELATIONSHIP SUPPORT",
		"Trust %d • Respect %d • Comfort %d\nCommitment %d • Compatibility %d • Satisfaction %d\nJealousy %d • Resentment %d" % [
			int(meters.get("trust", 0)), int(meters.get("respect", 0)), int(meters.get("comfort", 0)),
			int(meters.get("commitment", 0)), int(meters.get("compatibility", 0)), int(meters.get("satisfaction", 0)),
			int(meters.get("jealousy", 0)), int(meters.get("resentment", 0)),
		],
		"",
		"STORY ARC — CHAPTER %d OF 5" % int(profile.get("chapter_level", 1)),
		str(chapter.get("title", "This chapter has not been authored yet.")),
	]
	var date_status: Dictionary = RelationshipService.date_status(character_id)
	lines.append("\nDATE PLAN\n%s" % date_status.get("reason", "No date is scheduled."))
	var conflicts: Array = meters.get("conflict_history", [])
	if not conflicts.is_empty() and conflicts.back() is Dictionary:
		var latest_conflict: Dictionary = conflicts.back()
		lines.append("\nLATEST CONFLICT\n%s" % latest_conflict.get("reaction_line", "The relationship needs an honest conversation."))
	app_content.text = "\n".join(lines)
	_add_action_button("← All Relationships", _close_relationship_detail)

	var pending_proposal: Variant = profile.get("pending_agreement_proposal")
	if pending_proposal is Dictionary:
		_add_action_button("Accept %s proposal" % str(pending_proposal.get("type", "relationship")).capitalize(), _respond_relationship_proposal.bind(character_id, true))
		_add_action_button("Decline proposal honestly", _respond_relationship_proposal.bind(character_id, false))

	if bool(date_status.get("scheduled", false)):
		var date_event: Dictionary = date_status.get("event", {})
		if bool(date_status.get("ready", false)):
			for approach_value: Variant in ContentRegistry.get_package("port_alder_relationship_system").get("date_approaches", []):
				if approach_value is Dictionary:
					var approach: Dictionary = approach_value
					_add_action_button(str(approach.get("name", "Begin Date")), _complete_relationship_date.bind(str(date_event.get("id", "")), str(approach.get("id", ""))))
		elif not date_event.is_empty():
			var destination: String = str(date_event.get("location", "")).get_slice(".", 0)
			if not destination.is_empty():
				_add_action_button("Plan route to date", _open_route_planner.bind(destination))
	else:
		_render_date_invitation_actions(character_id, bool(profile.get("romance_compatible", false)))

	var readiness: Dictionary = RelationshipService.can_propose_agreement(character_id)
	if bool(readiness.get("ok", false)):
		for agreement_type_value: Variant in readiness.get("options", []):
			var agreement_type: String = str(agreement_type_value)
			_add_action_button("Discuss %s dating" % agreement_type, _propose_relationship_agreement.bind(character_id, agreement_type))


func _render_date_invitation_actions(character_id: String, romance_compatible: bool) -> void:
	if not romance_compatible:
		return
	var partners: Array = RelationshipService.active_partner_ids(character_id)
	for activity_value: Variant in ContentRegistry.get_package("port_alder_relationship_system").get("date_activities", []):
		if not activity_value is Dictionary:
			continue
		var activity: Dictionary = activity_value
		for option_value: Variant in RelationshipService.invitation_options(character_id, str(activity.get("id", "")), 2):
			if not option_value is Dictionary:
				continue
			var option: Dictionary = option_value
			var label: String = "Invite — %s • %s %s" % [
				activity.get("name", "Date"), str(option.get("weekday", "")).left(3).capitalize(), str(option.get("block", "")).replace("_", " ").capitalize(),
			]
			_add_action_button(label, _invite_on_date.bind(character_id, str(activity.get("id", "")), option, true))
			if not partners.is_empty():
				_add_action_button("Private invite — %s" % label.trim_prefix("Invite — "), _invite_on_date.bind(character_id, str(activity.get("id", "")), option, false))


func _open_relationship_detail(character_id: String) -> void:
	_selected_relationship_contact = character_id
	_render_relationships()


func _close_relationship_detail() -> void:
	_selected_relationship_contact = ""
	_render_relationships()


func _invite_on_date(character_id: String, activity_id: String, option: Dictionary, disclosed: bool) -> void:
	var result: Dictionary = RelationshipService.ask_out(
		character_id, activity_id, str(option.get("date", "")), str(option.get("weekday", "")), str(option.get("block", "")), disclosed
	)
	_render_relationships()
	if result.get("ok", false):
		phone_status.text = str(result.get("data", {}).get("response", "Invitation sent."))
		var warnings: PackedStringArray = PackedStringArray(result.get("data", {}).get("warnings", []))
		if not warnings.is_empty():
			phone_status.text += " WARNING: %s" % " ".join(warnings)
	else:
		phone_status.text = str(result.get("errors", ["The invitation could not be sent."])[0])


func _complete_relationship_date(event_id: String, approach_id: String) -> void:
	var result: Dictionary = RelationshipService.complete_date(event_id, approach_id)
	_render_relationships()
	if not result.get("ok", false):
		phone_status.text = str(result.get("errors", ["The date could not begin."])[0])
		return
	var data: Dictionary = result.get("data", {})
	phone_status.text = str(data.get("summary", "Date completed."))
	for chapter_value: Variant in data.get("chapter_updates", []):
		if chapter_value is Dictionary:
			phone_status.text += " New chapter: %s." % chapter_value.get("title", "Relationship story")
	var npc_proposal: Variant = data.get("npc_proposal")
	if npc_proposal is Dictionary:
		phone_status.text += " %s" % npc_proposal.get("message", "A relationship conversation is waiting.")
	for reaction_value: Variant in data.get("witness_reactions", []):
		if reaction_value is Dictionary:
			phone_status.text += " %s" % reaction_value.get("line", "")


func _propose_relationship_agreement(character_id: String, agreement_type: String) -> void:
	var result: Dictionary = RelationshipService.propose_agreement(character_id, agreement_type)
	_render_relationships()
	phone_status.text = str(result.get("data", {}).get("message", "Agreement discussed.")) if result.get("ok", false) else str(result.get("errors", ["The conversation could not begin."])[0])


func _respond_relationship_proposal(character_id: String, accept: bool) -> void:
	var result: Dictionary = RelationshipService.respond_to_npc_proposal(character_id, accept)
	_render_relationships()
	phone_status.text = str(result.get("data", {}).get("message", "Response recorded.")) if result.get("ok", false) else str(result.get("errors", ["The response could not be recorded."])[0])


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
	var save_lines: PackedStringArray = ["\n\nSAVE GAME"]
	var quick_summary: Dictionary = SaveService.summary_for_slot(SaveService.QUICKSAVE_SLOT)
	save_lines.append("Quicksave: %s" % SaveService.format_summary(quick_summary, true).replace("\n", " • "))
	for index: int in range(1, SaveService.MANUAL_SLOT_COUNT + 1):
		var slot_id: String = "manual_%d" % index
		var summary: Dictionary = SaveService.summary_for_slot(slot_id)
		save_lines.append("%s: %s" % [SaveService.slot_label(slot_id), SaveService.format_summary(summary, true).replace("\n", " • ")])
	var autosaves: Array = []
	for summary_value: Variant in SaveService.list_saves():
		if summary_value is Dictionary and str(summary_value.get("slot_id", "")).begins_with("autosave_"):
			autosaves.append(summary_value)
	if not autosaves.is_empty():
		save_lines.append("Latest autosave: %s" % SaveService.format_summary(autosaves[0], true).replace("\n", " • "))
	var binding_lines: PackedStringArray = []
	for action: String in SettingsService.REMAPPABLE_ACTIONS:
		binding_lines.append("%s: %s" % [SettingsService.action_name(action), SettingsService.binding_label(action)])
	app_content.text = "ACCESSIBILITY\nText size: %d%%\nReduce motion: %s\nHigh contrast: %s\nScreen-edge effects: %s\nCamera shake: %s\nDialogue skip: %s (K / controller shortcut)\n\nAUDIO\nMaster: %d%% • Music: %d%% • Ambience: %d%%\nUI: %d%% • Voice: %d%%\n\nDISPLAY\nMode: %s • Window: %s • VSync: %s\n\nCONTROLS\n%s\n\nSettings and saves remain on this device unless you copy them yourself.%s" % [
		int(SettingsService.text_scale * 100.0), _on_off(SettingsService.reduce_motion), _on_off(SettingsService.high_contrast),
		_on_off(SettingsService.screen_effects_enabled), _on_off(SettingsService.camera_shake_enabled), SettingsService.dialogue_skip_mode.capitalize(),
		int(SettingsService.master_volume * 100.0), int(SettingsService.music_volume * 100.0), int(SettingsService.ambience_volume * 100.0), int(SettingsService.ui_volume * 100.0), int(SettingsService.voice_volume * 100.0),
		SettingsService.display_mode.capitalize(), SettingsService.window_size, _on_off(SettingsService.vsync_enabled),
		"\n".join(binding_lines), "\n".join(save_lines),
	]
	_add_action_button("Text Size — %d%% (Cycle)" % int(SettingsService.text_scale * 100.0), _cycle_text_size)
	_add_action_button("Reduce Motion — %s" % _on_off(SettingsService.reduce_motion), _toggle_reduce_motion)
	_add_action_button("High Contrast — %s" % _on_off(SettingsService.high_contrast), _toggle_high_contrast)
	_add_action_button("Screen-Edge Effects — %s" % _on_off(SettingsService.screen_effects_enabled), _toggle_screen_effects)
	_add_action_button("Camera Shake — %s" % _on_off(SettingsService.camera_shake_enabled), _toggle_camera_shake)
	_add_action_button("Dialogue Skip Mode — %s" % SettingsService.dialogue_skip_mode.capitalize(), _toggle_dialogue_skip_mode)
	for channel: String in ["master", "music", "ambience", "ui", "voice"]:
		_add_action_button("%s Volume −" % channel.capitalize(), _adjust_audio_volume.bind(channel, -0.1))
		_add_action_button("%s Volume +" % channel.capitalize(), _adjust_audio_volume.bind(channel, 0.1))
	_add_action_button("Display Mode — %s" % SettingsService.display_mode.capitalize(), _cycle_display_mode)
	_add_action_button("Window Size — %s" % SettingsService.window_size, _cycle_window_size)
	_add_action_button("VSync — %s" % _on_off(SettingsService.vsync_enabled), _toggle_vsync)
	for action: String in SettingsService.REMAPPABLE_ACTIONS:
		_add_action_button("Remap %s" % SettingsService.action_name(action), _begin_control_remap.bind(action))
	_add_action_button("Reset Controls to Defaults", _reset_control_bindings)
	_add_action_button("Quicksave", _quicksave_game)
	if SaveService.has_slot(SaveService.QUICKSAVE_SLOT):
		_add_action_button("Quickload", _load_save_from_phone.bind(SaveService.QUICKSAVE_SLOT))
	for index: int in range(1, SaveService.MANUAL_SLOT_COUNT + 1):
		var slot_id: String = "manual_%d" % index
		var save_label: String = "Save to %s" % SaveService.slot_label(slot_id)
		if _pending_manual_overwrite == slot_id:
			save_label = "Confirm Overwrite — %s" % SaveService.slot_label(slot_id)
		_add_action_button(save_label, _save_manual_game.bind(index))
		if SaveService.has_slot(slot_id):
			_add_action_button("Load %s" % SaveService.slot_label(slot_id), _load_save_from_phone.bind(slot_id))
	for autosave_id_value: Variant in SaveService.autosave_slot_ids():
		var autosave_id: String = str(autosave_id_value)
		if SaveService.has_slot(autosave_id):
			_add_action_button("Load %s" % SaveService.slot_label(autosave_id), _load_save_from_phone.bind(autosave_id))
	_add_action_button("Quicksave and Return to Main Menu", _quicksave_and_return_to_menu)
	call_deferred("_apply_accessibility_settings")


func _quicksave_game() -> void:
	_pending_manual_overwrite = ""
	var result: Dictionary = SaveService.quicksave()
	phone_status.text = "Quicksave complete." if result.get("ok", false) else _save_error(result)
	_render_settings()


func _save_manual_game(slot_number: int) -> void:
	var slot_id: String = "manual_%d" % slot_number
	if SaveService.has_slot(slot_id) and _pending_manual_overwrite != slot_id:
		_pending_manual_overwrite = slot_id
		phone_status.text = "%s already has a save. Press Confirm Overwrite to replace it." % SaveService.slot_label(slot_id)
		_render_settings()
		return
	var allow_overwrite: bool = _pending_manual_overwrite == slot_id
	var result: Dictionary = SaveService.save_manual(slot_number, allow_overwrite)
	_pending_manual_overwrite = ""
	phone_status.text = "%s saved." % SaveService.slot_label(slot_id) if result.get("ok", false) else _save_error(result)
	_render_settings()


func _load_save_from_phone(slot_id: String) -> void:
	_pending_manual_overwrite = ""
	var result: Dictionary = SaveService.load_slot(slot_id)
	if not result.get("ok", false):
		phone_status.text = _save_error(result)
		return
	close_phone()
	get_tree().change_scene_to_file(SaveService.resume_scene_path())


func _save_error(result: Dictionary) -> String:
	var errors: Variant = result.get("errors", [])
	if (errors is Array or errors is PackedStringArray) and not errors.is_empty():
		return str(errors[0])
	return "The save operation could not be completed."


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
	if RelationshipService.is_date_event(event_id):
		var date_result: Dictionary = RelationshipService.cancel_date(event_id)
		phone_status.text = str(date_result.get("data", {}).get("message", "Date cancelled.")) if date_result.get("ok", false) else str(date_result.get("errors", ["Cancellation failed."])[0])
		_render_calendar()
		return
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
	var current: int = SettingsService.TEXT_SCALES.find(SettingsService.text_scale)
	SettingsService.text_scale = SettingsService.TEXT_SCALES[posmod(current + 1, SettingsService.TEXT_SCALES.size())]
	_save_and_refresh_settings()


func _toggle_reduce_motion() -> void:
	SettingsService.reduce_motion = not SettingsService.reduce_motion
	_save_and_refresh_settings()


func _toggle_high_contrast() -> void:
	SettingsService.high_contrast = not SettingsService.high_contrast
	_save_and_refresh_settings()


func _toggle_screen_effects() -> void:
	SettingsService.screen_effects_enabled = not SettingsService.screen_effects_enabled
	_save_and_refresh_settings()


func _toggle_camera_shake() -> void:
	SettingsService.camera_shake_enabled = not SettingsService.camera_shake_enabled
	_save_and_refresh_settings()


func _toggle_dialogue_skip_mode() -> void:
	SettingsService.dialogue_skip_mode = "toggle" if SettingsService.dialogue_skip_mode == "hold" else "hold"
	_save_and_refresh_settings()


func _adjust_audio_volume(channel: String, amount: float) -> void:
	SettingsService.set_audio_volume(channel, SettingsService.audio_volume(channel) + amount)
	_save_and_refresh_settings()


func _cycle_display_mode() -> void:
	SettingsService.display_mode = "fullscreen" if SettingsService.display_mode == "windowed" else "windowed"
	_save_and_refresh_settings()


func _cycle_window_size() -> void:
	var current: int = SettingsService.WINDOW_SIZES.find(SettingsService.window_size)
	SettingsService.window_size = SettingsService.WINDOW_SIZES[posmod(current + 1, SettingsService.WINDOW_SIZES.size())]
	_save_and_refresh_settings()


func _toggle_vsync() -> void:
	SettingsService.vsync_enabled = not SettingsService.vsync_enabled
	_save_and_refresh_settings()


func _begin_control_remap(action: String) -> void:
	_pending_remap_action = action
	phone_status.text = "Press a keyboard key or controller input for %s." % SettingsService.action_name(action)


func _reset_control_bindings() -> void:
	_pending_remap_action = ""
	SettingsService.reset_control_bindings()
	_save_and_refresh_settings()


func _save_and_refresh_settings() -> void:
	var error: Error = SettingsService.save_settings()
	phone_status.text = "Settings saved." if error == OK else "Settings could not be saved."
	_render_settings()
	_apply_accessibility_settings()


func _apply_accessibility_settings() -> void:
	SettingsService.apply_accessibility(self)


func _quicksave_and_return_to_menu() -> void:
	var result: Dictionary = SaveService.quicksave()
	if not result.get("ok", false):
		phone_status.text = _save_error(result)
		return
	close_phone()
	get_tree().change_scene_to_file(AppConstants.MAIN_MENU_SCENE)


func _add_action_button(label: String, callback: Callable) -> void:
	var button: Button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 39)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	app_actions.add_child(button)
	SettingsService.apply_accessibility(button)


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


func _employment_application(job_id: String) -> Dictionary:
	for application: Variant in GameState.current_state["player"]["employment"].get("applications", []):
		if application is Dictionary and str(application.get("job_id", "")) == job_id and str(application.get("stage", "")) not in ["declined", "withdrawn"]:
			return application
	return {}


func _active_employment_job(job_id: String) -> Dictionary:
	for active_job: Variant in GameState.current_state["player"]["employment"].get("active_jobs", []):
		if active_job is Dictionary and str(active_job.get("job_id", "")) == job_id and str(active_job.get("status", "active")) == "active":
			return active_job
	return {}


func _latest_payroll_record(job_id: String) -> Dictionary:
	var records: Array = GameState.current_state["player"]["employment"].get("payroll_history", [])
	for index: int in range(records.size() - 1, -1, -1):
		if records[index] is Dictionary and str(records[index].get("job_id", "")) == job_id:
			return records[index]
	return {}


func _employment_record_by_id(records: Array, record_id: String) -> Dictionary:
	for record: Variant in records:
		if record is Dictionary and str(record.get("id", "")) == record_id:
			return record
	return {}


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


func _phone_date_value(date: String) -> int:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	return -1 if parts.size() != 3 else int(parts[0]) * 372 + int(parts[1]) * 31 + int(parts[2])


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
