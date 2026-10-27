@tool
extends EditorPlugin

var _scene_tabs: Control
var _tabbar_hbox: HBoxContainer
var _script_menu: HBoxContainer
var _distraction_free: Button
var _script_mode := false


func _enter_tree() -> void:
	var base := EditorInterface.get_base_control()
	var matches := base.find_children("*", "EditorSceneTabs", true, false)
	if matches.is_empty():
		push_error("Hide Scene Tabs: EditorSceneTabs was not found. Scene tabs were left unchanged.")
		return

	var scene_tabs: Control = matches.front()
	var tabbar_hbox := _find_tabbar_hbox(scene_tabs)
	var script_menu := _find_script_menu()
	var distraction_free := _find_distraction_free_button(scene_tabs)
	if tabbar_hbox == null or script_menu == null or distraction_free == null:
		push_error("Hide Scene Tabs: Could not find the distraction-free button or the script toolbar. Scene tabs were left unchanged.")
		return

	_scene_tabs = scene_tabs
	_tabbar_hbox = tabbar_hbox
	_script_menu = script_menu
	_distraction_free = distraction_free
	_distraction_free.tree_entered.connect(_on_distraction_free_tree_entered)
	main_screen_changed.connect(_on_main_screen_changed)

	var script_screen := EditorInterface.get_script_editor().get_parent()
	_on_main_screen_changed("Script" if script_screen.visible else "")


func _exit_tree() -> void:
	_script_mode = false
	_restore_distraction_free_button()
	if _distraction_free != null and is_instance_valid(_distraction_free):
		if _distraction_free.tree_entered.is_connected(_on_distraction_free_tree_entered):
			_distraction_free.tree_entered.disconnect(_on_distraction_free_tree_entered)
	if main_screen_changed.is_connected(_on_main_screen_changed):
		main_screen_changed.disconnect(_on_main_screen_changed)
	if _scene_tabs != null and is_instance_valid(_scene_tabs):
		_scene_tabs.visible = true


func _on_main_screen_changed(screen_name: String) -> void:
	if _scene_tabs == null or not is_instance_valid(_scene_tabs):
		return
	if screen_name == "Script":
		_script_mode = true
		_park_distraction_free_button()
		_scene_tabs.visible = false
	else:
		_script_mode = false
		_restore_distraction_free_button()
		_scene_tabs.visible = true


func _on_distraction_free_tree_entered() -> void:
	if not _script_mode or _distraction_free == null or not is_instance_valid(_distraction_free):
		return
	if _is_under_scene_tabs(_distraction_free):
		_park_distraction_free_button.call_deferred()


func _park_distraction_free_button() -> void:
	if not _script_mode:
		return
	if _distraction_free == null or not is_instance_valid(_distraction_free):
		return
	if _script_menu == null or not is_instance_valid(_script_menu):
		return
	if not _is_under_scene_tabs(_distraction_free):
		return
	_distraction_free.reparent(_script_menu)
	_script_menu.move_child(_distraction_free, _script_menu.get_child_count() - 1)


func _restore_distraction_free_button() -> void:
	if _distraction_free == null or not is_instance_valid(_distraction_free):
		return
	if _script_menu == null or not is_instance_valid(_script_menu):
		return
	if _tabbar_hbox == null or not is_instance_valid(_tabbar_hbox):
		return
	if _distraction_free.get_parent() != _script_menu:
		return
	_distraction_free.reparent(_tabbar_hbox)
	_tabbar_hbox.move_child(_distraction_free, _tabbar_hbox.get_child_count() - 1)


func _is_under_scene_tabs(node: Node) -> bool:
	if _scene_tabs == null or node == null:
		return false
	var current := node.get_parent()
	while current != null:
		if current == _scene_tabs:
			return true
		current = current.get_parent()
	return false


func _find_tabbar_hbox(scene_tabs: Control) -> HBoxContainer:
	for child in scene_tabs.get_children():
		if child is PanelContainer and child.get_child_count() > 0 and child.get_child(0) is HBoxContainer:
			return child.get_child(0)
	return null


func _find_script_menu() -> HBoxContainer:
	var script_editor := EditorInterface.get_script_editor()
	if script_editor == null:
		return null
	var main_vbox := _find_main_vbox(script_editor)
	if main_vbox == null:
		return null
	for child in main_vbox.get_children():
		if child is HBoxContainer:
			return child
	return null


func _find_main_vbox(script_editor: Node) -> VBoxContainer:
	for child in script_editor.get_children():
		if child is VBoxContainer:
			return child
	if script_editor.get_child_count() == 0:
		return null
	for child in script_editor.get_child(0).get_children():
		if child is VBoxContainer:
			return child
	return null


func _find_distraction_free_button(scene_tabs: Control) -> Button:
	for node in scene_tabs.find_children("*", "Button", true, false):
		if node is MenuButton:
			continue
		var button := node as Button
		if button != null and button.toggle_mode and button.shortcut != null:
			return button
	var base := EditorInterface.get_base_control()
	for node in base.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.has_meta("_scene_tabs_owned"):
			return button
	return null
