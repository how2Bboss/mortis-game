extends Area3D

var state = false
var glowMat = preload("res://GAME_OBJECTS/Interactables/TallButton1/ButtonGlow.tres")
var offMat = preload("res://GAME_OBJECTS/Interactables/TallButton1/ButtonOff.tres")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _interact():
	if !$ButtonPressAnim.is_playing():
		$ButtonPressAnim.play("ButtonPress")
		match state:
			false:
				state = true
				$"../ButtonPart".set_surface_override_material(0, glowMat)
				$OmniLight3D.show()
			true: 
				state = false
				$"../ButtonPart".set_surface_override_material(0, offMat)
				$OmniLight3D.hide()
