extends RayCast3D

var reticleTextInteract 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reticleTextInteract = $"../../UI/ReticleCenter/Reticle/InteractText" 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	_sitBehavior()
	_interactBehavior()


func _sitBehavior():
	if get_collider() is Area3D and $"../ability_grab".object_grabbed == null:
		if get_collider().has_method("_sit"):
			var ObjSit = get_collider().find_child("SitPosition")
			var ObjStand = get_collider().find_child("StandPosition")
			var angleCheck = false
			
			if $"../../".sitting:
				reticleTextInteract.set_text("Stand")
			else:
				reticleTextInteract.set_text("Sit")
			
			if abs(ObjSit.global_rotation_degrees.x) > 45:
				reticleTextInteract.set_text("Can't Sit")
			elif abs(ObjSit.global_rotation_degrees.z) > 45:
				reticleTextInteract.set_text("Can't Sit")
			else:
				angleCheck = true
			
			if Input.is_action_just_pressed("interact"):
				if angleCheck:
					$"../../".sit(ObjSit, get_collider().get_parent(), false)
	
	elif !reticleTextInteract.text == "":
		reticleTextInteract.set_text("")

func _interactBehavior():
	if get_collider() is Area3D and $"../ability_grab".object_grabbed == null:
		if get_collider().has_method("_interact"):
			reticleTextInteract.set_text("Use")
			if Input.is_action_just_pressed("interact"):
				get_collider()._interact()
			
