extends Control

var savesList = []
var itemSelected = -1
var saveFileName = "PLACEHOLDER"
@onready var saveListPath = $HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Load/MarginContainer/VBoxContainer/SaveList
@onready var playerNode = $"../Main/Character"
@onready var DayNightCycleNode = $"../Main/DayNightCycle"
@onready var OBJ_HANDLERNode = $"../Main/OBJ_HANDLER"

func _ready() -> void:
	DirAccess.make_dir_absolute("user://saves")
	_load_saves_list()
	

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		queue_free()
	

func _on_close_menu_pressed() -> void:
	queue_free()


func _on_delete_button_pressed() -> void:
	if itemSelected != -1:
		$HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Load/MarginContainer/VBoxContainer/HBoxContainer2/DeleteButton/Popup.show()


func _on_popup_close_requested() -> void:
	pass # Replace with function body.

func _on_cancel_delete_pressed() -> void:
	$HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Load/MarginContainer/VBoxContainer/HBoxContainer2/DeleteButton/Popup.hide()


func _on_confirm_delete_pressed() -> void:
	saveListPath.remove_item(itemSelected)
	var fileToDelete = DirAccess.get_files_at("user://saves")[itemSelected]
	$HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Load/MarginContainer/VBoxContainer/HBoxContainer2/DeleteButton/Popup.hide()
	if fileToDelete == null:
		print("ERROR! FILE DOES NOT EXIST")
	else:
		OS.alert(str("user://saves/", fileToDelete),"SUCCESSFULLY DELETED FILE")
		DirAccess.remove_absolute(str("user://saves/", fileToDelete))
	saveListPath.deselect_all()
	itemSelected = -1

func _on_save_list_item_selected(index: int) -> void:
	itemSelected = index

func _on_save_button_pressed() -> void:
	_save_game()

func _save_game():
	var filenametext = $HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Load/MarginContainer/VBoxContainer/HBoxContainer/FILENAME.text
	_load_saves_list() #updates save list so save number is correct
	
	if filenametext:
		saveFileName = filenametext
	else:
		saveFileName = str("SAVE ",savesList.size(), " ", Time.get_date_string_from_system())
	
	var saved_game:saveGame = saveGame.new()
	
	saved_game.time_anim_pos = DayNightCycleNode.get_current_animation_position()
	saved_game.time_speed = 1.0/($"../Main/".minPerDay)
	saved_game.time_current_anim = DayNightCycleNode.get_current_animation()
	
	saved_game.player_position = playerNode.global_position
	saved_game.player_velocity = playerNode.velocity
	saved_game.player_rotation = playerNode.get_child(4).global_rotation
	saved_game.player_stamina = playerNode.stamina
	saved_game.player_flashlight_state = playerNode.get_child(4).get_child(1).visible
	saved_game.player_inventory = playerNode.get_child(7).get_child(2).items
	saved_game.player_inventory_icons = playerNode.get_child(7).get_child(2).itemsIcons
	
	save_objects(saved_game)
	
	ResourceSaver.save(saved_game, str("user://saves/", saveFileName,".tres"))
	
	_load_saves_list()

func _load_saves_list():
	saveListPath.clear()
	savesList = DirAccess.get_files_at("user://saves")
	#print(savesList)
	for i in savesList.size():
		saveListPath.add_item(savesList[i])


func _on_load_button_pressed() -> void:
	if itemSelected == -1:
		print("no item selected")
		return
	var file = DirAccess.get_files_at("user://saves")
	file = file[itemSelected]
	var save_file:saveGame = ResourceLoader.load(str("user://saves/",file))
	print(save_file)
	
	loadTimeOfDay(save_file)
	loadPlayerData(save_file)
	loadObjects(save_file)

func save_objects(saved_game:saveGame): #loops over every node with the level objects tag
	var levelObjects = get_tree().get_nodes_in_group("LevelObjects")
	var packedObjectsInArray = []
	for object in levelObjects:
		var packedObj = PackedScene.new()
		packedObj.pack(object)
		packedObjectsInArray.append(packedObj)
	saved_game.OBJ_HANDLER = packedObjectsInArray

func loadObjects(file:saveGame): #itterates through the saved array and instantiates the objects
	for node in OBJ_HANDLERNode.get_children():
		node.queue_free()

	for packedObject:PackedScene in file.OBJ_HANDLER:
		var object = packedObject.instantiate()
		object.add_to_group("LevelObjects", true)
		#print(str(object, packedObject))
		OBJ_HANDLERNode.add_child(object)
		

func loadPlayerData(file:saveGame):
	#loads player position, velocity, direction, etc from the save file
	playerNode.global_position = file.player_position
	playerNode.velocity = file.player_velocity
	playerNode.get_child(4).global_rotation = file.player_rotation
	playerNode.stamina = file.player_stamina
	playerNode.get_child(4).get_child(1).visible = file.player_flashlight_state
	playerNode.get_child(7).get_child(2).items = file.player_inventory
	playerNode.get_child(7).get_child(2).itemsIcons = file.player_inventory_icons
	playerNode.sitting = file.player_sitting
	playerNode.sittingObj = file.player_sittingObj
	#refreshes players inventory icons
	playerNode.get_child(7).get_child(2).inventoryNode.clear()
	for item in file.player_inventory_icons: #loops over all items and adds icons to player's inventory
		var ObjectName = item[0]
		var Icon = item[1]
		playerNode.get_child(7).get_child(2).inventoryNode.add_item(ObjectName, Icon)

func loadTimeOfDay(file:saveGame): #sets time of day and time speed scale
	DayNightCycleNode.play(file.time_current_anim, -1, file.time_speed)
	DayNightCycleNode.seek(file.time_anim_pos,true)
