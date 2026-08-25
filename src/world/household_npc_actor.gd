extends CharacterBody2D

var character_id: String = ""
var display_name: String = "Household Member"
var activity_label: String = "At home"
var accent_color: Color = Color("67c6c3")


func configure(schedule_entry: Dictionary, color_hex: String) -> void:
	character_id = str(schedule_entry.get("character_id", ""))
	display_name = str(schedule_entry.get("display_name", character_id))
	activity_label = str(schedule_entry.get("activity_label", "At home"))
	accent_color = Color(color_hex)
	var coordinates: Array = schedule_entry.get("position", [0.0, 0.0])
	position = Vector2(float(coordinates[0]), float(coordinates[1]))
	name = character_id.to_pascal_case()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, 17), 20.0, Color(0.0, 0.0, 0.0, 0.24))
	draw_circle(Vector2.ZERO, 21.0, accent_color)
	draw_circle(Vector2(0, -8), 11.0, Color("e8c3aa"))
	draw_rect(Rect2(-14, 4, 28, 28), accent_color.darkened(0.18), true)
	draw_circle(Vector2.ZERO, 21.0, Color("eef6f5"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-70, -34), display_name, HORIZONTAL_ALIGNMENT_CENTER, 140, 16, Color("eef6f5"))
	draw_string(ThemeDB.fallback_font, Vector2(-78, 51), activity_label, HORIZONTAL_ALIGNMENT_CENTER, 156, 13, Color("b7c9c9"))
