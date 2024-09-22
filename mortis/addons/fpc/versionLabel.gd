extends Label

func _on_tree_entered() -> void:
	set_text("v" + ProjectSettings.get_setting("application/config/version"))
