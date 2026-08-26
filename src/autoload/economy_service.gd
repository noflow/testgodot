extends Node

signal economy_state_changed
signal economy_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const EconomyEngineScript: GDScript = preload("res://src/economy/economy_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	_engine = EconomyEngineScript.new(ContentRegistry, SimulationEngineScript.new(ContentRegistry))


func sync_economy() -> Dictionary:
	return _commit(_engine.sync_economy(GameState.current_state))


func current_budget_summary() -> Dictionary:
	return {} if not GameState.has_active_game() else _engine.current_budget_summary(GameState.current_state)


func list_stores() -> Array:
	return [] if not GameState.has_active_game() else _engine.list_stores(GameState.current_state)


func store_listing(store_id: String) -> Dictionary:
	return {} if not GameState.has_active_game() else _engine.store_listing(GameState.current_state, store_id)


func purchase(store_id: String, item_id: String, quantity: int = 1) -> Dictionary:
	return _commit(_engine.purchase(GameState.current_state, store_id, item_id, quantity))


func pay_tuition(amount: float = 0.0) -> Dictionary:
	return _commit(_engine.pay_tuition(GameState.current_state, amount))


func pay_outstanding_rent() -> Dictionary:
	return _commit(_engine.pay_outstanding_rent(GameState.current_state))


func pay_credit_card(amount: float = 0.0) -> Dictionary:
	return _commit(_engine.pay_credit_card(GameState.current_state, amount))


func _commit(result: Dictionary) -> Dictionary:
	if not result.get("ok", false):
		economy_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	economy_state_changed.emit()
	return result
