extends RefCounted
class_name PortAlderGameClock

const BLOCKS: PackedStringArray = [
	"early_morning", "morning", "lunch", "afternoon",
	"evening", "late_evening", "night",
]
const BLOCK_MINUTES: Dictionary = {
	"early_morning": 180,
	"morning": 240,
	"lunch": 60,
	"afternoon": 240,
	"evening": 240,
	"late_evening": 180,
	"night": 300,
}
const WEEKDAYS: PackedStringArray = [
	"monday", "tuesday", "wednesday", "thursday",
	"friday", "saturday", "sunday",
]


func advance(clock: Dictionary, payload: Dictionary) -> Dictionary:
	var blocks: int = int(payload.get("blocks", 0))
	var minutes: int = int(payload.get("minutes", 0))
	if blocks < 0 or minutes < 0 or (blocks == 0 and minutes == 0):
		return {"ok": false, "error": "Time advance requires positive blocks or minutes."}

	var result: Dictionary = {
		"ok": true,
		"blocks_crossed": 0,
		"days_crossed": 0,
		"weeks_crossed": 0,
		"months_crossed": 0,
		"years_crossed": 0,
		"minutes_advanced": 0,
	}
	for _index: int in blocks:
		_advance_one_block(clock, result)
	_advance_minutes(clock, minutes, result)
	return result


func timestamp(clock: Dictionary) -> String:
	return "Y%d-%02d-%02d:%s+%03d" % [
		int(clock.get("year", 1)),
		int(clock.get("month", 1)),
		int(clock.get("day", 1)),
		str(clock.get("block", "early_morning")),
		int(clock.get("minute_within_block", 0)),
	]


func block_index(block: String) -> int:
	return BLOCKS.find(block)


func _advance_minutes(clock: Dictionary, minutes: int, result: Dictionary) -> void:
	var remaining: int = minutes
	while remaining > 0:
		var block: String = str(clock.get("block", "early_morning"))
		var duration: int = int(BLOCK_MINUTES.get(block, 180))
		var minute: int = int(clock.get("minute_within_block", 0))
		var available: int = duration - minute
		if remaining < available:
			clock["minute_within_block"] = minute + remaining
			result["minutes_advanced"] += remaining
			remaining = 0
		else:
			remaining -= available
			_advance_one_block(clock, result)


func _advance_one_block(clock: Dictionary, result: Dictionary) -> void:
	var current_block: String = str(clock.get("block", "early_morning"))
	var current_index: int = block_index(current_block)
	if current_index < 0:
		current_index = 0
	var next_index: int = current_index + 1
	result["minutes_advanced"] += int(BLOCK_MINUTES.get(current_block, 180)) - int(clock.get("minute_within_block", 0))
	clock["minute_within_block"] = 0
	result["blocks_crossed"] += 1
	if next_index < BLOCKS.size():
		clock["block"] = BLOCKS[next_index]
		return
	clock["block"] = BLOCKS[0]
	_advance_one_day(clock, result)


func _advance_one_day(clock: Dictionary, result: Dictionary) -> void:
	var previous_month: int = int(clock.get("month", 1))
	var previous_year: int = int(clock.get("year", 1))
	var day: int = int(clock.get("day", 1)) + 1
	var month: int = previous_month
	var year: int = previous_year
	if day > _days_in_month(month, year):
		day = 1
		month += 1
		result["months_crossed"] += 1
		if month > 12:
			month = 1
			year += 1
			result["years_crossed"] += 1

	clock["day"] = day
	clock["month"] = month
	clock["year"] = year
	clock["season"] = _season_for_month(month)
	result["days_crossed"] += 1

	var weekday_index: int = WEEKDAYS.find(str(clock.get("weekday", "monday")))
	weekday_index = posmod(weekday_index + 1, WEEKDAYS.size())
	clock["weekday"] = WEEKDAYS[weekday_index]
	if weekday_index == 0:
		clock["week_number"] = int(clock.get("week_number", 1)) + 1
		result["weeks_crossed"] += 1


func _days_in_month(month: int, year: int) -> int:
	match month:
		4, 6, 9, 11:
			return 30
		2:
			return 29 if year % 4 == 0 else 28
		_:
			return 31


func _season_for_month(month: int) -> String:
	if month in [3, 4, 5]:
		return "spring"
	if month in [6, 7, 8]:
		return "summer"
	if month in [9, 10, 11]:
		return "autumn"
	return "winter"
