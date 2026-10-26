@tool
extends EditorPlugin

var _scene_tabs: Control


func _enter_tree() -> void:
	var base := EditorInterface.get_base_control()
	var matches := base.find_children("*", "EditorSceneTabs", true, false)
	if matches.is_empty():
		push_error("Hide Scene Tabs: EditorSceneTabs was not found. Scene tabs were left unchanged.")
		return

	_scene_tabs = matches.front()
	main_screen_changed.connect(_on_main_screen_changed)

	var script_screen := EditorInterface.get_script_editor().get_parent()
	_on_main_screen_changed("Script" if script_screen.visible else "")


func _exit_tree() -> void:
	if main_screen_changed.is_connected(_on_main_screen_changed):
		main_screen_changed.disconnect(_on_main_screen_changed)
	if _scene_tabs != null and is_instance_valid(_scene_tabs):
		_scene_tabs.visible = true


func _on_main_screen_changed(screen_name: String) -> void:
	if _scene_tabs == null or not is_instance_valid(_scene_tabs):
		return
	_scene_tabs.visible = screen_name != "Script"
