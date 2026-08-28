extends Node

const APP_NAME: String = "Port Alder Life Sim"
const APP_VERSION: String = "0.1.0-dev"
const TARGET_GODOT_VERSION: String = "4.7.2"

const MAIN_MENU_SCENE: String = "res://scenes/menus/main_menu.tscn"
const BOOT_SCENE: String = "res://scenes/boot/boot.tscn"
const CHARACTER_CREATION_SCENE: String = "res://scenes/creation/character_creation.tscn"
const VN_DIALOGUE_SCENE: String = "res://scenes/dialogue/vn_dialogue.tscn"
const HALE_HOME_SCENE: String = "res://scenes/locations/hale_home.tscn"
const CITY_LOCATION_SCENE: String = "res://scenes/locations/city_location.tscn"
const SANDBOX_SCENE: String = HALE_HOME_SCENE

const COLOR_BACKGROUND: Color = Color("#091016")
const COLOR_PANEL: Color = Color("#13232c")
const COLOR_PRIMARY: Color = Color("#67c6c3")
const COLOR_ACCENT: Color = Color("#e9a86c")
const COLOR_TEXT: Color = Color("#eef6f5")
const COLOR_MUTED: Color = Color("#9eb4b5")
const COLOR_ERROR: Color = Color("#ef7777")

const REQUIRED_FOUNDATION_FILES: PackedStringArray = [
	"res://content/vertical_slice/manifest.json",
	"res://content/runtime/new_game_state.json",
	"res://content/systems/character_creation.json",
	"res://content/systems/home_interactions.json",
	"res://content/systems/city_interactions.json",
	"res://content/systems/phone.json",
	"res://content/opening/opening_week.json",
	"res://content/world/all_locations.json",
	"res://content/systems/economy.json",
	"res://content/systems/inventory.json",
	"res://content/systems/simulation_events.json",
	"res://content/systems/save_system.json",
	"res://content/systems/relationships.json",
	"res://content/systems/quest_progression.json",
	"res://content/systems/housing.json",
	"res://schemas/save_game.schema.json",
]
