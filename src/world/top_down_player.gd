extends CharacterBody2D

signal interact_requested(world_position: Vector2)

@export var movement_speed: float = 230.0
var movement_enabled: bool = true


func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * movement_speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if movement_enabled and event.is_action_pressed("interact"):
		interact_requested.emit(global_position)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 18.0, Color("67c6c3"))
	draw_circle(Vector2.ZERO, 18.0, Color("eef6f5"), false, 3.0)
	draw_line(Vector2(-7, -2), Vector2(7, -2), Color("091016"), 3.0)
