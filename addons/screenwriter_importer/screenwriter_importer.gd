@tool
extends EditorPlugin

const IMPORT_SCRIPT := "res://tools/import_screenwriter_package.py"

var _picker: FileDialog
var _confirmation: ConfirmationDialog
var _result: AcceptDialog
var _selected_package: String = ""


func _enter_tree() -> void:
	add_tool_menu_item("Import Screenwriter Package…", _open_picker)
	_picker = FileDialog.new()
	_picker.title = "Choose a Screenwriter game package"
	_picker.access = FileDialog.ACCESS_FILESYSTEM
	_picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_picker.filters = PackedStringArray([
		"*.screenwriter-package ; Screenwriter game packages",
		"*.json ; JSON packages",
	])
	_picker.file_selected.connect(_preview_package)
	_editor_root().add_child(_picker)

	_confirmation = ConfirmationDialog.new()
	_confirmation.title = "Import Screenwriter Package"
	_confirmation.ok_button_text = "Import and create backup"
	_confirmation.confirmed.connect(_apply_package)
	_confirmation.min_size = Vector2i(760, 500)
	_editor_root().add_child(_confirmation)

	_result = AcceptDialog.new()
	_result.title = "Screenwriter Package Import"
	_result.min_size = Vector2i(700, 420)
	_editor_root().add_child(_result)


func _exit_tree() -> void:
	remove_tool_menu_item("Import Screenwriter Package…")
	for dialog: Window in [_picker, _confirmation, _result]:
		if is_instance_valid(dialog):
			dialog.queue_free()


func _editor_root() -> Control:
	return get_editor_interface().get_base_control()


func _open_picker() -> void:
	_picker.current_path = ""
	_picker.popup_centered_ratio(0.72)


func _preview_package(path: String) -> void:
	_selected_package = path
	var preview := _run_importer(false)
	_confirmation.dialog_text = str(preview.output)
	_confirmation.get_ok_button().disabled = int(preview.code) != 0
	_confirmation.popup_centered(Vector2i(780, 520))


func _apply_package() -> void:
	if _selected_package.is_empty():
		return
	var imported := _run_importer(true)
	_result.dialog_text = str(imported.output)
	_result.title = "Screenwriter import complete" if int(imported.code) == 0 else "Screenwriter import failed"
	_result.popup_centered(Vector2i(720, 440))
	if int(imported.code) == 0:
		get_editor_interface().get_resource_filesystem().scan()


func _run_importer(apply: bool) -> Dictionary:
	var script_path := ProjectSettings.globalize_path(IMPORT_SCRIPT)
	var arguments := PackedStringArray([script_path, _selected_package])
	if apply:
		arguments.append("--apply")
	var output: Array = []
	var code := OS.execute("python3", arguments, output, true)
	var text := "\n".join(output)
	if text.strip_edges().is_empty():
		text = "The importer returned no details. Exit code: %d" % code
	return {"code": code, "output": text}
