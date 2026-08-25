extends Node

signal operation_applied(event: Dictionary)
signal operation_rejected(operation: String, errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	_engine = SimulationEngineScript.new(ContentRegistry)


func apply_operation(operation: String, payload: Dictionary, source: String) -> Dictionary:
	if _engine == null:
		_engine = SimulationEngineScript.new(ContentRegistry)
	var result: Dictionary = _engine.apply_operation(GameState.current_state, operation, payload, source)
	if not result.get("ok", false):
		var errors: PackedStringArray = result.get("errors", PackedStringArray(["Unknown simulation error."]))
		operation_rejected.emit(operation, errors)
		return result
	GameState.replace_state(result["state"])
	operation_applied.emit(result["event"].duplicate(true))
	return {"ok": true, "event": result["event"].duplicate(true), "errors": PackedStringArray()}
