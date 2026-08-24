extends Control

@onready var status_label: Label = %StatusLabel
@onready var detail_label: Label = %DetailLabel
@onready var progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	progress_bar.value = 10.0
	call_deferred("_run_boot_validation")


func _run_boot_validation() -> void:
	status_label.text = "Validating Port Alder content…"
	progress_bar.value = 35.0
	await get_tree().process_frame

	var errors: PackedStringArray = ContentRegistry.validate_foundation()
	progress_bar.value = 85.0
	await get_tree().process_frame

	if not errors.is_empty():
		_show_errors(errors)
		return

	status_label.text = "Content ready"
	detail_label.text = "Opening First Week Foundations"
	progress_bar.value = 100.0
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file(AppConstants.MAIN_MENU_SCENE)


func _show_errors(errors: PackedStringArray) -> void:
	status_label.text = "Content validation failed"
	status_label.modulate = AppConstants.COLOR_ERROR
	detail_label.text = "\n".join(errors)
	progress_bar.value = 100.0

