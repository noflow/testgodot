extends Node

const GameClockScript: GDScript = preload("res://src/simulation/game_clock.gd")

var _clock_rules: RefCounted = GameClockScript.new()


func advance_blocks(blocks: int, source: String = "gameplay") -> Dictionary:
	return SimulationService.apply_operation("time.advance", {"blocks": blocks}, source)


func advance_minutes(minutes: int, source: String = "gameplay") -> Dictionary:
	return SimulationService.apply_operation("time.advance", {"minutes": minutes}, source)


func get_clock() -> Dictionary:
	if not GameState.has_active_game():
		return {}
	return GameState.current_state.get("clock", {}).duplicate(true)


func get_block_names() -> PackedStringArray:
	return _clock_rules.BLOCKS.duplicate()


func get_block_duration(block: String) -> int:
	return int(_clock_rules.BLOCK_MINUTES.get(block, 0))


func get_timestamp() -> String:
	var clock: Dictionary = get_clock()
	return "" if clock.is_empty() else _clock_rules.timestamp(clock)
