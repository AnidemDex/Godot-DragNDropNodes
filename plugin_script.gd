@tool
extends EditorPlugin

class ClassTree extends Tree:
	var root: TreeItem
	var editor_interface: EditorInterface  # Reference to the EditorInterface

	func _init(_editor_interface: EditorInterface) -> void:
		editor_interface = _editor_interface
		name = "Nodes"
		item_selected.connect(_item_selected)

	func generate_class_tree() -> void:
		clear()

		var editor_theme: Theme = editor_interface.get_editor_theme()

		# Create the root item
		root = create_item()
		root.set_text(0, "Nodes")
		root.set_icon(0, editor_theme.get_icon("Node", "EditorIcons"))

		# Create section headers under the root
		var root_2d = create_item(root)
		root_2d.set_text(0, "2D Nodes")
		root_2d.set_icon(0, editor_theme.get_icon("Node2D", "EditorIcons"))

		var root_3d = create_item(root)
		root_3d.set_text(0, "3D Nodes")
		root_3d.set_icon(0, editor_theme.get_icon("Node3D", "EditorIcons"))

		var root_misc = create_item(root)
		root_misc.set_text(0, "Misc")
		root_misc.set_icon(0, editor_theme.get_icon("Node", "EditorIcons"))

		var root_all = create_item(root)
		root_all.set_text(0, "All Nodes")
		root_all.set_icon(0, editor_theme.get_icon("Node", "EditorIcons"))

		# Get all Node classes
		var node_classes = ClassDB.get_inheriters_from_class("Node")

		# Initialize arrays to hold classes for each section
		var nodes_2d = []
		var nodes_3d = []
		var nodes_misc = []
		var nodes_all = []

		# Categorize the classes into the respective sections
		for _class_name in node_classes:
			# Apply filters to exclude unwanted classes
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

			# Add to 'All Nodes' section
			nodes_all.append(_class_name)

			# Categorize based on class name
			if "2D" in _class_name:
				nodes_2d.append(_class_name)
			elif "3D" in _class_name:
				nodes_3d.append(_class_name)
			else:
				nodes_misc.append(_class_name)

		# Sort the lists alphabetically
		nodes_2d.sort()
		nodes_3d.sort()
		nodes_misc.sort()
		nodes_all.sort()

		# Populate each section with its classes
		create_tree_items(nodes_2d, root_2d, editor_theme)
		create_tree_items(nodes_3d, root_3d, editor_theme)
		create_tree_items(nodes_misc, root_misc, editor_theme)
		create_tree_items(nodes_all, root_all, editor_theme)

	func create_tree_items(class_list: Array, parent_item: TreeItem, editor_theme: Theme):
		for _class_name in class_list:
			var class_item = create_item(parent_item)
			var class_icon = editor_theme.get_icon("Node", "EditorIcons")
			if editor_theme.has_icon(_class_name, "EditorIcons"):
				class_icon = editor_theme.get_icon(_class_name, "EditorIcons")
			class_item.set_text(0, _class_name)
			class_item.set_icon(0, class_icon)
			class_item.set_selectable(0, ClassDB.can_instantiate(_class_name))

	func _item_selected() -> void:
		var item = get_selected()
		if item == null:
			return
		var node: Node = ClassDB.instantiate(item.get_text(0)) as Node
		var scene_root = editor_interface.get_edited_scene_root()
		if scene_root == null:
			return
		scene_root.add_child(node, true)
		node.owner = scene_root
		item.set_metadata(0, node.get_path())
		var selection: EditorSelection = editor_interface.get_selection()
		selection.clear()
		selection.add_node(node)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_READY:
			generate_class_tree()

	func _get_drag_data(at_position: Vector2) -> Variant:
		var item = get_item_at_position(at_position)
		if item == null or item.get_metadata(0) == null:
			return null
		return {"type": "nodes", "nodes": [item.get_metadata(0)]}

var class_tree: ClassTree

func _enter_tree() -> void:
	class_tree = ClassTree.new(get_editor_interface())
	add_control_to_dock(DOCK_SLOT_LEFT_UL, class_tree)

func _exit_tree() -> void:
	remove_control_from_docks(class_tree)
	class_tree.queue_free()
