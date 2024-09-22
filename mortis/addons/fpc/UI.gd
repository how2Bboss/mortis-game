extends Control

var playerImmobileState := false
var animDayNight

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animDayNight = find_parent("Main").find_child("DayNightCycle")
	$PAUSE.hide()

func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("pause"):
		
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				playerImmobileState = $"../".immobile
				$"../".paused = true
				$PAUSE.show()
				$MarginContainer.hide()
				get_tree().physics_interpolation = false
				get_tree().paused = true
				$"../Head/Camera".attributes.set_dof_blur_far_enabled(true)
				$"../".immobile = true
				$"../".inventory = false
				$INVENTORY/TabContainer/Inventory/InventoryVbox/ListsHbox/Item.deselect_all()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE:
				$"../".paused = false
				get_tree().paused = false
				get_tree().physics_interpolation = true
				$PAUSE.hide()
				$MarginContainer.show()
				$"../Head/Camera".attributes.set_dof_blur_far_enabled(false)
				$"../".immobile = playerImmobileState
				$"../".inventory = false
				$INVENTORY/TabContainer/Inventory/InventoryVbox/ListsHbox/Item.deselect_all()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("inventory") && !$"../".paused:
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				$"../".inventory = true
				$"../".immobile = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE:
				$"../".inventory = false
				$"../".immobile = false
				$INVENTORY/TabContainer/Inventory/InventoryVbox/ListsHbox/Item.deselect_all()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var time = animDayNight.get_current_animation_position()
	var timeh = floor(time/2.5)
	var timem = floor(time*24)
	var times = floor(time*1440)
	timeh = fmod(timeh+6, 24)
	timem = fmod(timem, 60)
	times = fmod(times, 60)
	timeh = str("%0*d" % [2, timeh])
	timem = str("%0*d" % [2, timem])
	times = str("%0*d" % [2, times])
	$MarginContainer/TopLeftUI/CLOCK.set_text(str(timeh,":",timem,":",times))
	


func _on_item_item_selected(index: int) -> void:
	pass # Replace with function body.


func _on_item_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
	pass # Replace with function body.
