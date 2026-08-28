extends RefCounted
class_name PortAlderHaleHomeNavigation

const OUTSIDE_ROOM: String = "front_yard"
const ROOM_EXITS: Dictionary = {
	"player_bedroom": {"down": "upstairs_landing"},
	"upstairs_landing": {"up": "player_bedroom", "left": "upstairs_hall", "down": "entryway"},
	"upstairs_hall": {"left": "lily_bedroom", "up": "parents_bedroom", "right": "upstairs_landing", "down": "family_bathroom"},
	"lily_bedroom": {"right": "upstairs_hall"},
	"parents_bedroom": {"down": "upstairs_hall"},
	"family_bathroom": {"up": "upstairs_hall"},
	"entryway": {"left": "living_room", "up": "upstairs_landing", "right": "front_yard"},
	"living_room": {"right": "entryway", "down": "dining_room"},
	"dining_room": {"up": "living_room", "right": "kitchen"},
	"kitchen": {"left": "dining_room", "right": "laundry_room", "down": "backyard"},
	"backyard": {"up": "kitchen"},
	"laundry_room": {"left": "kitchen", "right": "garage"},
	"garage": {"left": "laundry_room", "down": "front_yard"},
	"front_yard": {"left": "garage", "up": "alder_heights_residential_street.hale_block", "down": "entryway"},
}
