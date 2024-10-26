@tool
extends EditorPlugin

var class_tree
const ClassTree = preload("res://addons/Godot-DragNDropNodes-main/class_tree.gd")  # Update the path if necessary

func _enter_tree() -> void:
	class_tree = ClassTree.new(get_editor_interface())
	add_control_to_dock(DOCK_SLOT_LEFT_UL, class_tree)

func _exit_tree() -> void:
	remove_control_from_docks(class_tree)
	class_tree.queue_free()
