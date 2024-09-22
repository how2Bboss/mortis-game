extends Node3D

var optionsMenu = preload("res://UI/options_menu.tscn")
@onready var settingsHandler = find_child("PreloadSettingsHandler")

@export var minPerDay = 24.0

func _ready() -> void:
	
	var speed = 1.0/minPerDay
	$DayNightCycle.play("DayNight", -1, speed)
	$DayNightCycle.seek(0)
	
	var newMenu = optionsMenu.instantiate()
	settingsHandler.add_child(newMenu)
	newMenu.queue_free()
	
	#1  	m per day 	0.042 min/ghr 	0.042 sec/gmin 	 0.0083 sec/gsec
	#24 	m per day 	1.000 min/ghr 	1.000 sec/gmin 	 0.0167 sec/gsec
	#48 	m per day 	2.000 min/ghr 	2.000 sec/gmin 	 0.0333 sec/gsec
	#60 	m per day 	2.500 min/ghr 	2.500 sec/gmin 	 0.0417 sec/gsec
	#1440 	m per day 	60.00 min/ghr 	60.00 sec/gmin 	 1.0000 sec/gsec
	
	
