@tool
extends EditorPlugin

class ClassTree extends Tree:
	var root:TreeItem
	# Trust me, unless you have a lot of time, do not implement search:
	# https://github.com/godotengine/godot/blob/b4ba0f983a02f671862cdddfa6a4808b226e9b6b/editor/create_dialog.cpp#L177
	func generate_class_tree() -> void:
		clear()
		
		var class_list = ClassDB.get_class_list()
		var _handled := []
		var editor_theme := EditorInterface.get_editor_theme()
		
		root = create_item()
		root.set_text(0, "Node")
		root.set_icon(0, editor_theme.get_icon("Node", "EditorIcons"))
		
		var data = {}
		# This line "sorts" the list. Ideally, data should be used as the tree to create groups I guess
		data["Node"] = ClassDB.get_inheriters_from_class("Node")
		for _class_name in data["Node"]:
			if "Editor" in _class_name:
				continue
			if _class_name == "ScriptCreateDialog":
				continue
			if not ClassDB.is_parent_class(_class_name, "Node"):
				continue
			if ClassDB.is_parent_class("Node", _class_name):
				continue
			if not ClassDB.is_class_enabled(_class_name):
				continue
			if _class_name == "Node":
				continue
			
			var class_item := create_item(root)
			var class_icon := editor_theme.get_icon("Node", "EditorIcons")
			if editor_theme.has_icon(_class_name, "EditorIcons"):
				class_icon = editor_theme.get_icon(_class_name, "EditorIcons")
			
			class_item.set_text(0, _class_name)
			class_item.set_icon(0, class_icon)
			class_item.set_selectable(0, ClassDB.can_instantiate(_class_name))
	
	func _get_drag_data(at_position: Vector2) -> Variant:
		var item = get_item_at_position(at_position)
		if item.get_metadata(0) == null:
			return
		
		return {"type":"nodes", "nodes": [item.get_metadata(0)]}
		return "Hello"
	
	func _item_selected() -> void:
		var item: = get_selected()
		var node:Node = ClassDB.instantiate(item.get_text(0)) as Node
		EditorInterface.get_edited_scene_root().add_child(node, true)
		node.owner = EditorInterface.get_edited_scene_root()
		item.set_metadata(0, node.get_path())
		var selection := EditorInterface.get_selection()
		selection.clear()
		selection.add_node(node)
	
	func _notification(what: int) -> void:
		if what == NOTIFICATION_READY:
			generate_class_tree()
	
	func _init() -> void:
		name = "Nodes"
		item_selected.connect(_item_selected)

var class_tree:ClassTree

func _enter_tree() -> void:
	class_tree = ClassTree.new()
	tree_exited.connect(class_tree.queue_free)
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UL, class_tree)

func _exit_tree() -> void:
	remove_control_from_docks(class_tree)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		print(get_viewport().gui_get_drag_data())
