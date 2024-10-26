@tool
class_name ClassTree
extends VBoxContainer

# Variable Declarations
var root: TreeItem
var editor_interface: EditorInterface  # Reference to the EditorInterface
var search_bar: LineEdit              # The search bar
var tree: Tree                        # The tree displaying nodes
var full_node_list: Array = []        # Full list of node classes

func _init(_editor_interface: EditorInterface) -> void:
	editor_interface = _editor_interface
	name = "Nodes"

	# Initialize the search bar
	search_bar = LineEdit.new()
	search_bar.placeholder_text = "Search Nodes..."
	search_bar.clear_button_enabled = true  # Enable the clear button
	add_child(search_bar)

	# Connect the text_changed signal
	search_bar.text_changed.connect(self._on_search_text_changed)

	# Initialize the tree
	tree = Tree.new()

	# Set the tree to expand vertically
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	add_child(tree)

	# Connect to 'item_activated' signal
	tree.item_activated.connect(self._on_item_activated)

	# Generate the full node list
	generate_full_node_list()

	# Generate the class tree initially
	generate_class_tree()

func generate_full_node_list() -> void:
	# Generate the full list of node classes once
	full_node_list.clear()  # Ensure the list is empty before populating
	var node_classes = ClassDB.get_inheriters_from_class("Node")

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

		full_node_list.append(_class_name)

	# Sort the full list alphabetically
	full_node_list.sort()

func generate_class_tree() -> void:
	tree.clear()

	var editor_theme: Theme = editor_interface.get_editor_theme()

	# Create the root item
	root = tree.create_item()
	root.set_text(0, "Nodes")
	root.set_icon(0, editor_theme.get_icon("Node", "EditorIcons"))

	# Create section headers under the root
	var root_2d = tree.create_item(root)
	root_2d.set_text(0, "2D Nodes")
	root_2d.set_icon(0, editor_theme.get_icon("Node2D", "EditorIcons"))

	var root_3d = tree.create_item(root)
	root_3d.set_text(0, "3D Nodes")
	root_3d.set_icon(0, editor_theme.get_icon("Node3D", "EditorIcons"))

	var root_misc = tree.create_item(root)
	root_misc.set_text(0, "Misc")
	root_misc.set_icon(0, editor_theme.get_icon("Node", "EditorIcons"))

	var root_all = tree.create_item(root)
	root_all.set_text(0, "All Nodes")
	root_all.set_icon(0, editor_theme.get_icon("Node", "EditorIcons"))

	# Initialize arrays to hold classes for each section
	var nodes_2d: Array = []
	var nodes_3d: Array = []
	var nodes_misc: Array = []
	var nodes_all: Array = []

	# Get the search text
	var search_text = search_bar.text.strip_edges().to_lower()

	# Filter the full node list based on the search text
	for _class_name in full_node_list:
		# If there's a search query, filter the classes
		if search_text != "" and not _class_name.to_lower().findn(search_text) != -1:
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

	# Populate each section with its classes
	create_tree_items(nodes_2d, root_2d, editor_theme)
	create_tree_items(nodes_3d, root_3d, editor_theme)
	create_tree_items(nodes_misc, root_misc, editor_theme)
	create_tree_items(nodes_all, root_all, editor_theme)

func create_tree_items(class_list: Array, parent_item: TreeItem, editor_theme: Theme) -> void:
	for _class_name in class_list:
		var class_item = tree.create_item(parent_item)
		var class_icon = editor_theme.get_icon("Node", "EditorIcons")
		if editor_theme.has_icon(_class_name, "EditorIcons"):
			class_icon = editor_theme.get_icon(_class_name, "EditorIcons")
		class_item.set_text(0, _class_name)
		class_item.set_icon(0, class_icon)
		class_item.set_selectable(0, ClassDB.can_instantiate(_class_name))

func _on_item_activated() -> void:
	var item = tree.get_selected()
	if item == null:
		return
	print("Item activated:", item.get_text(0))
	_create_node(item)

func _create_node(item: TreeItem) -> void:
	var node_type = item.get_text(0)
	print("Creating node of type:", node_type)
	var node: Node = ClassDB.instantiate(node_type) as Node
	if node == null:
		print("Failed to instantiate node of type:", node_type)
		return
	var scene_root = editor_interface.get_edited_scene_root()
	if scene_root == null:
		print("No scene root found")
		return
	scene_root.add_child(node, true)
	node.owner = scene_root
	var selection: EditorSelection = editor_interface.get_selection()
	selection.clear()
	selection.add_node(node)
	print("Node created and added to the scene.")

func _on_search_text_changed(new_text: String) -> void:
	# Regenerate the class tree whenever the search text changes
	generate_class_tree()
