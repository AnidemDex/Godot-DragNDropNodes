@tool
class_name ClassTree
extends VBoxContainer

# Variable Declarations
var root: TreeItem
var editor_interface: EditorInterface  # Reference to the EditorInterface
var search_bar: LineEdit              # The search bar
var tree: Tree                        # The tree displaying nodes
var full_node_list: Array = []        # Full list of node classes
var root_items_collapsed_state = {
	"Popular": true,
	"2D Nodes": true,
	"3D Nodes": true,
	"Misc": true,
	"All Nodes": true,
}
var is_search_active = false

# Define the list of popular nodes in the order you want them displayed.
# Placing Node and Node2D at the top ensures they appear there in the UI.
var popular_nodes = [
	"Node",
	"Node2D",
	"RigidBody2D",
	"CharacterBody2D",
	"Sprite2D",
	"CollisionShape2D",
	"Area2D",
	"AnimationPlayer",
	"AnimatedSprite2D",
	"StaticBody2D",
	"Camera2D",
	"CanvasLayer",
	"Label",
	"Panel"
]

func _init(_editor_interface: EditorInterface) -> void:
	editor_interface = _editor_interface
	name = "Nodes"

	# Initialize the search bar
	search_bar = LineEdit.new()
	search_bar.placeholder_text = "Search Nodes..."
	search_bar.clear_button_enabled = true  # Enable the clear button
	add_child(search_bar)
	search_bar.text_changed.connect(self._on_search_text_changed)

	# Initialize the tree
	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.set_drag_forwarding(_get_drag_data_fw, Callable(), Callable())

	add_child(tree)

	tree.item_activated.connect(self._on_item_activated)
	tree.item_collapsed.connect(self._on_item_collapsed)

	# Generate the full node list
	generate_full_node_list()

	# Generate the class tree initially
	generate_class_tree()

func generate_full_node_list() -> void:
	full_node_list.clear()
	var node_classes = ClassDB.get_inheriters_from_class("Node")
	node_classes.append("Node")  # Manually add "Node"

	for _class_name in node_classes:
		if _class_name == "Node":
			if ClassDB.can_instantiate(_class_name) and ClassDB.is_class_enabled(_class_name):
				full_node_list.append(_class_name)
			continue
		if _class_name == "MissingNode":
			continue
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
		if not ClassDB.can_instantiate(_class_name):
			continue
		full_node_list.append(_class_name)

	full_node_list.sort()
	if "Node" in full_node_list:
		full_node_list.erase("Node")
		full_node_list.insert(0, "Node")

func generate_class_tree() -> void:
	tree.clear()

	var editor_theme: Theme = editor_interface.get_editor_theme()

	var search_text = search_bar.text.strip_edges().to_lower()
	is_search_active = search_text != ""

	root = tree.create_item()
	root.set_text(0, "Nodes")
	root.set_icon(0, editor_theme.get_icon("Sprite2D", "EditorIcons"))
	root.set_disable_folding(true)

	var root_popular = tree.create_item(root)
	root_popular.set_text(0, "Popular")
	root_popular.set_icon(0, editor_theme.get_icon("RigidBody2D", "EditorIcons"))
	if is_search_active:
		root_popular.set_collapsed(false)
	else:
		root_popular.set_collapsed(root_items_collapsed_state.get("Popular", true))

	var root_2d = tree.create_item(root)
	root_2d.set_text(0, "2D Nodes")
	root_2d.set_icon(0, editor_theme.get_icon("Node2D", "EditorIcons"))
	if is_search_active:
		root_2d.set_collapsed(false)
	else:
		root_2d.set_collapsed(root_items_collapsed_state.get("2D Nodes", true))

	var root_3d = tree.create_item(root)
	root_3d.set_text(0, "3D Nodes")
	root_3d.set_icon(0, editor_theme.get_icon("Node3D", "EditorIcons"))
	if is_search_active:
		root_3d.set_collapsed(false)
	else:
		root_3d.set_collapsed(root_items_collapsed_state.get("3D Nodes", true))

	var root_misc = tree.create_item(root)
	root_misc.set_text(0, "Misc")
	root_misc.set_icon(0, editor_theme.get_icon("Control", "EditorIcons"))
	if is_search_active:
		root_misc.set_collapsed(false)
	else:
		root_misc.set_collapsed(root_items_collapsed_state.get("Misc", true))

	var root_all = tree.create_item(root)
	root_all.set_text(0, "All Nodes")
	root_all.set_icon(0, editor_theme.get_icon("Node", "EditorIcons"))
	if is_search_active:
		root_all.set_collapsed(false)
	else:
		root_all.set_collapsed(root_items_collapsed_state.get("All Nodes", true))

	var nodes_popular: Array = []
	var nodes_2d: Array = []
	var nodes_3d: Array = []
	var nodes_misc: Array = []
	var nodes_all: Array = []

	# Build nodes_popular in the order defined by popular_nodes
	for pn in popular_nodes:
		if pn in full_node_list:
			if not is_search_active or pn.to_lower().find(search_text) != -1:
				nodes_popular.append(pn)

	# Filter and categorize other nodes
	for _class_name in full_node_list:
		if is_search_active and _class_name.to_lower().find(search_text) == -1:
			continue

		# Add to 'All Nodes' section
		nodes_all.append(_class_name)

		# Categorize based on class name
		if "2D" in _class_name:
			nodes_2d.append(_class_name)
		elif "3D" in _class_name:
			nodes_3d.append(_class_name)
		else:
			if _class_name not in popular_nodes: # Don't double-include popular in misc
				nodes_misc.append(_class_name)

	# Ensure "Node" is at the top of "All Nodes"
	if "Node" in nodes_all:
		nodes_all.erase("Node")
		nodes_all.insert(0, "Node")

	create_tree_items(nodes_popular, root_popular, editor_theme)
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

func _get_drag_data_fw(at_position: Vector2) -> Variant:
	var current_scene = editor_interface.get_edited_scene_root()
	if not is_instance_valid(current_scene):
		return
	
	var item := tree.get_item_at_position(at_position)
	if not item:
		return
	
	var _class_name = item.get_text(0)
	if _class_name.is_empty():
		return
	
	if not ClassDB.can_instantiate(_class_name):
		return
	
	var instance:Node = ClassDB.instantiate(_class_name) as Node
	current_scene.add_child(instance, true)
	instance.owner = current_scene
	editor_interface.get_selection().clear()
	editor_interface.get_selection().add_node(instance)
	
	var editor_theme = editor_interface.get_editor_theme()
	var class_icon = editor_theme.get_icon("Node", "EditorIcons")
	if editor_theme.has_icon(_class_name, "EditorIcons"):
		class_icon = editor_theme.get_icon(_class_name, "EditorIcons")
	
	var hb  := HBoxContainer.new()
	var tr := TextureRect.new()
	var icon_size := get_theme_constant(&"class_icon_size", &"Editor")
	tr.custom_minimum_size = Vector2i(icon_size, icon_size)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.texture = class_icon
	hb.add_child(tr)
	var label := Label.new()
	label.text = _class_name
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hb.add_child(label)
	
	var tree_editor = Engine.get_meta("SceneTreeEditor", null)
	if is_instance_valid(tree_editor):
		var tree:Tree = tree_editor.get_child(0) as Tree
		if is_instance_valid(tree):
			tree.drop_mode_flags = Tree.DROP_MODE_ON_ITEM | Tree.DROP_MODE_INBETWEEN
			tree_editor.emit_signal("nodes_dragged")
	
	set_drag_preview(hb)
	return {"type":"nodes", "nodes": [instance.get_path()]}

func _on_item_activated() -> void:
	var item = tree.get_selected()
	if item == null:
		return
	_create_node(item)

func _create_node(item: TreeItem) -> void:
	var node_type = item.get_text(0)
	var node: Node = ClassDB.instantiate(node_type) as Node
	if node == null:
		return
	var scene_root = editor_interface.get_edited_scene_root()
	
	if not is_instance_valid(scene_root):
		var tree_editor = Engine.get_meta("SceneTreeEditor", null)
		var editor_node = Engine.get_meta("EditorNode", null)
		if not is_instance_valid(tree_editor) or not is_instance_valid(editor_node):
			node.free() # avoid leaked instance
			return
		editor_node.call("set_edited_scene", node)
		tree_editor.call("update_tree")
		return
	scene_root.add_child(node, true)
	node.owner = scene_root
	var selection: EditorSelection = editor_interface.get_selection()
	selection.clear()
	selection.add_node(node)

func _on_search_text_changed(new_text: String) -> void:
	generate_class_tree()

func _on_item_collapsed(item: TreeItem) -> void:
	var item_text = item.get_text(0)
	if item_text in ["Popular", "2D Nodes", "3D Nodes", "Misc", "All Nodes"]:
		root_items_collapsed_state[item_text] = item.is_collapsed()
