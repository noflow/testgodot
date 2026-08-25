extends Node

signal new_game_created(state: Dictionary)
signal state_cleared
signal state_replaced(state: Dictionary)

var current_state: Dictionary = {}


func start_new_game(player_choices: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	if ContentRegistry.get_document(NewGameStateFactory.TEMPLATE_PATH) == null:
		ContentRegistry.validate_foundation()
	if not ContentRegistry.get_last_errors().is_empty():
		return {}
	var factory: NewGameStateFactory = NewGameStateFactory.new(ContentRegistry)
	current_state = factory.create_new_game(player_choices, options)
	if not current_state.is_empty():
		new_game_created.emit(current_state.duplicate(true))
	return current_state.duplicate(true)


func has_active_game() -> bool:
	return not current_state.is_empty()


func replace_state(next_state: Dictionary) -> void:
	current_state = next_state
	state_replaced.emit(current_state.duplicate(true))


func clear_state() -> void:
	current_state.clear()
	state_cleared.emit()
