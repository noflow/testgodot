extends Control

const ValidatorScript: GDScript = preload("res://src/creation/character_creation_validator.gd")
const CREATION_PACKAGE: String = "port_alder_character_creation"
const ECONOMY_PACKAGE: String = "port_alder_economy_system"

@onready var tabs: TabContainer = %CreationTabs
@onready var first_name: LineEdit = %FirstName
@onready var last_name: LineEdit = %LastName
@onready var birth_date: LineEdit = %BirthDate
@onready var face_option: OptionButton = %FaceOption
@onready var eye_option: OptionButton = %EyeOption
@onready var skin_option: OptionButton = %SkinOption
@onready var hair_option: OptionButton = %HairOption
@onready var height_option: OptionButton = %HeightOption
@onready var body_option: OptionButton = %BodyOption
@onready var positive_options: GridContainer = %PositiveOptions
@onready var challenging_options: GridContainer = %ChallengingOptions
@onready var core_options: GridContainer = %CoreOptions
@onready var hobby_options: GridContainer = %HobbyOptions
@onready var positive_count: Label = %PositiveCount
@onready var challenging_count: Label = %ChallengingCount
@onready var core_count: Label = %CoreCount
@onready var hobby_count: Label = %HobbyCount
@onready var archetype_option: OptionButton = %ArchetypeOption
@onready var background_option: OptionButton = %BackgroundOption
@onready var background_summary: RichTextLabel = %BackgroundSummary
@onready var review_text: RichTextLabel = %ReviewText
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton

var _validator: RefCounted
var _config: Dictionary
var _selections: Dictionary = {
	"positive_traits": [],
	"challenging_traits": [],
	"core_values": [],
	"hobbies": [],
}
var _count_labels: Dictionary = {}


func _ready() -> void:
	SettingsService.settings_changed.connect(_apply_accessibility_settings)
	_apply_accessibility_settings()
	_config = ContentRegistry.get_package(CREATION_PACKAGE)
	_validator = ValidatorScript.new(ContentRegistry)
	_count_labels = {
		"positive_traits": positive_count,
		"challenging_traits": challenging_count,
		"core_values": core_count,
		"hobbies": hobby_count,
	}
	_populate_single(face_option, _config["appearance_options"]["face"])
	_populate_single(eye_option, _config["appearance_options"]["eye_color"])
	_populate_single(skin_option, _config["appearance_options"]["skin_tone"])
	_populate_single(hair_option, _config["appearance_options"]["hairstyle"])
	_populate_single(height_option, _config["appearance_options"]["height"])
	_populate_single(body_option, _config["appearance_options"]["body_type"])
	_populate_single(archetype_option, _config["archetypes"])
	_populate_single(background_option, ContentRegistry.get_package(ECONOMY_PACKAGE)["starting_budgets"], "financial")
	_populate_multi(positive_options, _config["positive_traits"], "positive_traits", 3)
	_populate_multi(challenging_options, _config["challenging_traits"], "challenging_traits", 3)
	_populate_multi(core_options, _config["core_values"], "core_values", 3)
	_populate_multi(hobby_options, _config["hobbies"], "hobbies", 2)
	_apply_accessibility_settings()
	tabs.current_tab = 0
	_update_navigation()
	first_name.grab_focus()


func _populate_single(option: OptionButton, definitions: Array, mode: String = "standard") -> void:
	option.clear()
	option.add_item("Select…")
	option.set_item_metadata(0, "")
	for definition: Variant in definitions:
		if not definition is Dictionary:
			continue
		var label: String = str(definition.get("name", definition.get("id", "Option")))
		if mode == "financial":
			label = str(definition.get("id", "")).trim_suffix("_background").capitalize()
		option.add_item(label)
		option.set_item_metadata(option.item_count - 1, definition.get("id", ""))
	option.select(0)


func _populate_multi(
	container: GridContainer,
	definitions: Array,
	group: String,
	maximum: int
) -> void:
	for definition: Variant in definitions:
		if not definition is Dictionary:
			continue
		var button: CheckButton = CheckButton.new()
		button.text = str(definition.get("name", definition.get("id", "Option")))
		button.tooltip_text = str(definition.get("description", ""))
		button.custom_minimum_size = Vector2(190, 38)
		button.toggled.connect(
			_on_multi_toggled.bind(button, group, str(definition.get("id", "")), maximum)
		)
		container.add_child(button)
	_update_count(group, maximum)


func _on_multi_toggled(
	pressed: bool,
	button: CheckButton,
	group: String,
	value: String,
	maximum: int
) -> void:
	var selected: Array = _selections[group]
	if pressed:
		if selected.size() >= maximum:
			button.set_pressed_no_signal(false)
			status_label.text = "Choose only %d %s. Deselect one before choosing another." % [maximum, group.replace("_", " ")]
			return
		selected.append(value)
	else:
		selected.erase(value)
	status_label.text = ""
	_update_count(group, maximum)


func _update_count(group: String, maximum: int) -> void:
	var label: Label = _count_labels.get(group)
	if label != null:
		label.text = "%d / %d selected" % [_selections[group].size(), maximum]


func _on_next_pressed() -> void:
	if tabs.current_tab < tabs.get_tab_count() - 1:
		tabs.current_tab += 1
		if tabs.current_tab == tabs.get_tab_count() - 1:
			_refresh_review()
		_update_navigation()
		return
	_confirm_creation()


func _on_back_pressed() -> void:
	if tabs.current_tab > 0:
		tabs.current_tab -= 1
		_update_navigation()


func _on_cancel_pressed() -> void:
	get_tree().change_scene_to_file(AppConstants.MAIN_MENU_SCENE)


func _on_tab_changed(_tab: int) -> void:
	if not is_node_ready():
		return
	if tabs.current_tab == tabs.get_tab_count() - 1:
		_refresh_review()
	_update_navigation()


func _on_background_selected(_index: int) -> void:
	if not is_node_ready() or _config.is_empty():
		return
	_refresh_background_summary()


func _update_navigation() -> void:
	back_button.disabled = tabs.current_tab == 0
	next_button.text = "Create Character & Begin" if tabs.current_tab == tabs.get_tab_count() - 1 else "Next"
	status_label.text = ""


func _refresh_background_summary() -> void:
	var background_id: String = _selected_id(background_option)
	var background: Dictionary = _find_by_id(
		ContentRegistry.get_package(ECONOMY_PACKAGE)["starting_budgets"], background_id
	)
	if background.is_empty():
		background_summary.text = "Select a financial background to review its starting support."
		return
	var accounts: Dictionary = background["accounts"]
	background_summary.text = (
		"[b]Starting finances[/b]\nCash: $%d   Checking: $%d   Savings: $%d\n\n"
		+ "[b]Weekly school allowance[/b]\n$%d while eligible\n\n"
		+ "[b]Family car access[/b]\n%s\n\n[b]Starting wardrobe[/b]\n%s tier"
	) % [
		accounts["wallet_cash"], accounts["checking"], accounts["savings"],
		background["weekly_school_allowance"],
		str(background["family_car_access"]).replace("_", " ").capitalize(),
		str(background["starting_clothing_tier"]).capitalize(),
	]


func _refresh_review() -> void:
	var choices: Dictionary = _build_choices()
	var validation: Dictionary = _validator.validate_choices(choices)
	var lines: PackedStringArray = ["[font_size=27][b]Review Your Character[/b][/font_size]"]
	lines.append("[b]Name[/b]  %s %s" % [choices["first_name"], choices["last_name"]])
	lines.append("[b]Birth date[/b]  %s  •  Age %d at opening" % [choices["birth_date"], _validator.age_on_opening_date(choices["birth_date"])])
	lines.append("[b]Gender identity[/b]  Male")
	lines.append("[b]Positive traits[/b]  %s" % ", ".join(choices["positive_traits"]))
	lines.append("[b]Challenging traits[/b]  %s" % ", ".join(choices["challenging_traits"]))
	lines.append("[b]Core values[/b]  %s" % ", ".join(choices["core_values"]))
	lines.append("[b]Archetype[/b]  %s" % choices["archetype"].replace("_", " ").capitalize())
	lines.append("[b]Hobbies[/b]  %s" % ", ".join(choices["hobbies"]))
	lines.append("[b]Financial background[/b]  %s" % choices["financial_background"].trim_suffix("_background").capitalize())
	if not validation["valid"]:
		lines.append("[color=#ef7777][b]Still required[/b]\n• %s[/color]" % "\n• ".join(validation["errors"]))
	else:
		lines.append("[color=#67c6c3]Ready. Trait effects and starting resources will be applied when the game begins.[/color]")
	review_text.text = "\n\n".join(lines)


func _confirm_creation() -> void:
	var choices: Dictionary = _build_choices()
	var validation: Dictionary = _validator.validate_choices(choices)
	if not validation["valid"]:
		status_label.text = "Character is incomplete. Review the highlighted requirements above."
		_refresh_review()
		return
	choices["birthday"] = _validator.birthday_from_birth_date(choices["birth_date"])
	var state: Dictionary = GameState.start_new_game(choices)
	if state.is_empty():
		status_label.text = "Character could not be created. Check the Content screen for errors."
		return
	var dialogue_result: Dictionary = DialogueService.begin("opening_future_talk")
	if not dialogue_result.get("ok", false):
		status_label.text = str(dialogue_result.get("errors", ["Opening scene could not start."])[0])
		return
	get_tree().change_scene_to_file(AppConstants.VN_DIALOGUE_SCENE)


func _build_choices() -> Dictionary:
	return {
		"first_name": first_name.text.strip_edges(),
		"last_name": last_name.text.strip_edges(),
		"birth_date": birth_date.text.strip_edges(),
		"appearance": {
			"face": _selected_id(face_option),
			"eye_color": _selected_id(eye_option),
			"skin_tone": _selected_id(skin_option),
			"hairstyle": _selected_id(hair_option),
			"height": _selected_id(height_option),
			"body_type": _selected_id(body_option),
		},
		"positive_traits": _selections["positive_traits"].duplicate(),
		"challenging_traits": _selections["challenging_traits"].duplicate(),
		"core_values": _selections["core_values"].duplicate(),
		"archetype": _selected_id(archetype_option),
		"hobbies": _selections["hobbies"].duplicate(),
		"financial_background": _selected_id(background_option),
	}


func _selected_id(option: OptionButton) -> String:
	return "" if option.selected < 0 else str(option.get_item_metadata(option.selected))


func _find_by_id(entries: Array, content_id: String) -> Dictionary:
	for entry: Variant in entries:
		if entry is Dictionary and str(entry.get("id", "")) == content_id:
			return entry
	return {}


func _apply_accessibility_settings() -> void:
	SettingsService.apply_accessibility(self)
