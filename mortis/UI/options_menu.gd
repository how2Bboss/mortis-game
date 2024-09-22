extends Control

var gameVer = ProjectSettings.get_setting("application/config/version")
const configFilePath = "user://config"
var config
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	config = ConfigFile.new()
	var err = config.load("user://config/options.cfg")
	var configVer : String
	
	for setting in config.get_sections():
		if config.get_value("GameVersion", "v") is String:
			configVer = config.get_value("GameVersion", "v")
		else:
			configVer = "NULL"
	
	var versionMismatch = (configVer == gameVer)
	
	if err == OK and versionMismatch:
		load_config()
	else:
		DirAccess.make_dir_absolute(configFilePath)
		create_new_config()
		load_config()

func create_new_config():
	#generates a new blank config file
	config = ConfigFile.new()
	#supply with all graphics, audio, and gameplay settings
	config.set_value("GameVersion", "v", gameVer)
	config.set_value("Display", "fullscreenMode", 2)
	config.set_value("Display", "resolution", 0)
	config.set_value("Display", "vsync", 0)
	config.set_value("Display", "grassMode", 0)
	
	config.set_value("Audio", "masterVolume", 0)
	config.save("user://config/options.cfg")




func load_config():
	for setting in config.get_sections():
		#loads display options
		_on_resolution_item_selected(config.get_value("Display", "resolution"))
		_on_fullscreen_mode_item_selected(config.get_value("Display", "fullscreenMode"))
		_on_vsync_item_selected(config.get_value("Display", "vsync"))
		_on_grass_mode_item_selected(config.get_value("Display", "grassMode"))
		#loads audio options
		_on_master_volume_slider_value_changed(config.get_value("Audio", "masterVolume"))

func save_config(section:String, key:String, value):
	for setting in config.get_sections():
		
		config.set_value(section,key,value)
		config.save("user://config/options.cfg")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		queue_free()

#shows and hides grass shells
func _update_grass_shells(enabled:bool) -> void:
	var grassShells = get_tree().get_nodes_in_group("shell_fur_instance_mesh")
	for shell in grassShells:
		if enabled:
			shell.show()
		else:
			shell.hide()

func _on_close_menu_pressed() -> void:
	queue_free()

func _on_resolution_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600,900))
		2:
			DisplayServer.window_set_size(Vector2i(1280,720))
	
	save_config("Display", "resolution", index)
	DisplayServer.window_set_position(Vector2i.ZERO)
	$"HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer2/Resolution".select(index)

func _on_fullscreen_mode_item_selected(index: int) -> void:
	match index:
		0:
			$"HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer2/Resolution".disabled = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			
		1: 
			$"HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer2/Resolution".disabled = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			
		2:
			$"HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer2/Resolution".disabled = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		3:
			$"HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer2/Resolution".disabled = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	save_config("Display", "fullscreenMode", index)
	$"HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer/FullscreenMode".select(index)

func _on_vsync_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
		1: 
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	save_config("Display", "vsync", index)
	$"HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer3/Vsync".select(index)


func _on_master_volume_slider_value_changed(value: float) -> void:
	var volume = clampf(value, -80, 6)
	$"HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Audio/MarginContainer/VBoxContainer/HBoxContainer/VolumeVal".set_text(str(value))
	$"HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Audio/MarginContainer/VBoxContainer/HBoxContainer/MasterVolumeSlider".set_value(value)
	AudioServer.set_bus_volume_db(0, volume)
	save_config("Audio", "masterVolume", volume)


func _on_grass_mode_item_selected(index: int) -> void:
	match index:
		0:
			_update_grass_shells(false)
		1:
			_update_grass_shells(true)
		2:
			_update_grass_shells(false)
	
	save_config("Display", "grassMode", index)
	$HBoxContainer/MarginContainer/CenterContainer/Panel/TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer4/GrassMode.select(index)
