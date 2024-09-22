extends Control
var optionsMenu = preload("res://UI/options_menu.tscn")
var saveLoadMenu = preload("res://UI/save_menu.tscn")

var loadMenu = null

var quitButtonState = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#makes sure user double clicks the quit button to prevent accidental exits
func _on_quit_pressed() -> void:
	match quitButtonState:
		0:
			$MarginContainer/HBoxContainer/VBoxContainer/Quit.set_text(" Quit?")
			quitButtonState = 1
		1:
			get_tree().quit()

func _on_quit_leave() -> void:
	quitButtonState = 0
	$MarginContainer/HBoxContainer/VBoxContainer/Quit.set_text(" Quit")

func _on_options_pressed() -> void:
	
	_reset_menus()
	
	loadMenu = optionsMenu.instantiate()
	loadMenu.show()
	$"../../../../".add_child(loadMenu)


func _on_save_pressed() -> void:
	
	_reset_menus()
	
	loadMenu = saveLoadMenu.instantiate()
	$"../../../../".add_child(loadMenu)

func _reset_menus():
	if loadMenu != null:
		loadMenu.queue_free()
