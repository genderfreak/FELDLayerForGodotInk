@tool
extends EditorPlugin

const AUTOLOAD_NAME = "GlobalAccess"

func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/feld_layer_for_godot_ink/global_access.gd")

func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
