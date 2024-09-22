extends RayCast3D

var mouseInput = Vector2(0,0)

@export var max_carry: float = 15.0
@export var lift_force_max = 8
@export var mass_limit = 200
@export var throw_force = 400

var speed_multi = 1.0

var reticle1 = preload("res://Textures/Reticles/Reticle1.png")
var reticle2 = preload("res://Textures/Reticles/Reticle2.png")
var reticle3 = preload("res://Textures/Reticles/Reticle3.png")
var reticle4 = preload("res://Textures/Reticles/Reticle4.png")

var reticlePath

var object_grabbed = null
var object_original_rotation = null

var can_use = true
var sphere = preload("res://GAME_OBJECTS/Sphere Mesh.tscn")
var sphere_instance = null
var vector1 = null
var vector2 = null
var vector3 = null
var player = null
var is_heavy = false
var angularDrag = 0
var linearDrag = 0


func _ready() -> void:
	reticlePath = $"../../UI/ReticleCenter/Reticle"
	player = find_parent("Character")

func _set_ui_text():
	var ObjName = null
	var Volume = "Can't Store"
	if object_grabbed.get_parent().has_method("_store"):
		ObjName = object_grabbed.get_parent().ObjectName
		Volume = object_grabbed.get_parent().Volume
	else:
		ObjName = object_grabbed.get_parent().name
		if object_grabbed.get_parent().has_meta("Name"):
			ObjName = object_grabbed.get_parent().get_meta("Name")
	
	var UItext = str("Mass: ", "%.1f" % object_grabbed.mass, "kg\n", "Weight: ", round(object_grabbed.mass*2.2046226218487756), "lbs")
	$"../../UI/ReticleCenter/Reticle/ReticleText".set_text(str("Name: ",ObjName, "\n", "Volume: ", Volume, "\n", UItext))
func _physics_process(delta: float) -> void:
	
	var hover = get_collider() != null && get_collider() is RigidBody3D
	if hover:
		_set_reticle(reticle2)
	elif !(get_collider() is RigidBody3D):
		_set_reticle(reticle1)
	
	if Input.is_action_just_pressed("grab") and !$"../../".immobile and can_use: #picks up an object or drags vehicle
		if $"../../".sittingObj == null:
			if not object_grabbed:
				if (get_collider() is RigidBody3D or get_collider() is VehicleBody3D) and get_collider().mass <= mass_limit:
					can_use = false
					object_grabbed = get_collider()
					$GrabPosition3D.global_rotation = object_grabbed.global_rotation
					$GrabPosition3D.global_basis = object_grabbed.global_basis
					is_heavy = false
					_set_ui_text()
					sphere_instance = sphere.instantiate()
					object_grabbed.add_child(sphere_instance)
					if object_grabbed.mass > max_carry:
						is_heavy = true
						$GrabPosition3D.global_rotation = self.global_rotation
						sphere_instance.global_transform.origin = get_collision_point()
					else:
						sphere_instance.global_transform.origin = get_collision_point()
		else:
			can_use = true
	
	if Input.is_action_just_released("grab"): #lets go of the object when the mouse is no longer held
		if sphere_instance != null:
			release()
		if is_heavy == false && object_grabbed:
			release()
	
	if Input.is_action_just_pressed("throw"): #throws the held object and reduces stamina if object is heavy
		if object_grabbed:
			if is_heavy:
				if $"../../".stamina - object_grabbed.mass/10 >= 0:
					$"../../".stamina_drain(object_grabbed.mass/10)
					object_grabbed.apply_force(global_transform.basis.z*-throw_force, vector1.normalized()*.3)
					release()
			else:
				object_grabbed.apply_force(global_transform.basis.z*-throw_force*(object_grabbed.mass/10))
				release()
	
	if $"../../".immobile && object_grabbed: #releases the grabbed object if the player status is immobie
		release()
	
	if object_grabbed: #updates reticle
		_set_reticle(reticle3)
		#gets the rigid bodies parent and sees if it has the store function. If it does, the object can be put in the players inventory
		if object_grabbed.get_parent().has_method("_store") and Input.is_action_just_pressed("interact"):
			object_grabbed.get_parent()._store()
			$"../../AudioStreamPlayer".play()
			release()
		else:
		
			if is_heavy: #calls different grab functions depending on the mass of the object
				_grab_heavy()
				if $"../../".stamina <= 0: #drops object if stamina reaches 0 (only applies to heavy objects)
					release()
			else:
				_grab_light()
	
	mouseInput = Vector2.ZERO #resets mouse delta

func release():
	$"../../UI/ReticleCenter/Reticle/ReticleText".set_text(str(""))
	if is_heavy:
		pass
	else:
		object_grabbed.angular_velocity = Vector3.ZERO
	sphere_instance.queue_free()
	object_grabbed.set_angular_damp(0.1)
	object_grabbed.set_linear_damp(0)
	
	object_grabbed = null
	object_original_rotation = null
	can_use = true
	$GrabPosition3D.global_rotation = self.global_rotation

func _set_reticle(texture):
	if reticlePath.get_texture() != texture:
		reticlePath.set_texture(texture)

func _grab_heavy():
	
	#var grab_point = (get_collision_point() - object_grabbed.global_transform.origin).normalized()
	vector1 = sphere_instance.global_transform.origin - object_grabbed.global_transform.origin
	vector2 = $GrabPosition3D.global_transform.origin - sphere_instance.global_transform.origin
	vector3 = $GrabPosition3D.global_transform.origin - object_grabbed.global_transform.origin
	var v4 = $"../../".global_transform.origin - sphere_instance.global_transform.origin
	sphere_instance.look_at($GrabPosition3D.position)
	var grab_length = vector3.length()/10
	var strength = vector2.length()*150*(grab_length*grab_length)*(object_grabbed.mass/2) #should be based on distance from grab point to obj origin to prevent obj spaz
	if strength > lift_force_max:
			strength = lift_force_max
	object_grabbed.apply_impulse(vector2*strength-object_grabbed.linear_velocity, vector1.normalized())
	var newton_law = -(vector2*strength-object_grabbed.linear_velocity)*0.06
	$"../../".velocity += newton_law.normalized() * clamp(newton_law.length(), -0.5, 0.5) * Vector3(1,0.5,1)
	newton_law *= Vector3(1.0,4.0,1.0)
	$"../../".stamina_drain(clamp(newton_law.length()*0.1, 0.0, 0.8)*2.0)
	object_grabbed.set_angular_damp(15)
	
	if vector2.length() > 2:
		release()
	
func _grab_light():
	if Input.is_action_pressed("rotate"):
		$GrabPosition3D.rotate_y(mouseInput.x * 0.003)
		$GrabPosition3D.rotate_x(mouseInput.y * 0.003)
	vector1 = sphere_instance.global_transform.origin - object_grabbed.global_transform.origin
	vector2 = ($GrabPosition3D.global_transform.origin + $GrabPosition3D.global_basis.z*1) - sphere_instance.global_transform.origin
	vector3 = $GrabPosition3D.global_transform.origin - object_grabbed.global_transform.origin
	
	var grab_length = vector3.length()/1
	var damp = 1.0
	var strength = vector3.length()*50*(grab_length*grab_length)*(object_grabbed.mass/2)
	if object_grabbed.mass < 2.0:
		strength = clamp(strength, -5.0, 5.0)
		damp = object_grabbed.mass/2.0
	if strength > lift_force_max:
		strength = lift_force_max
	object_grabbed.apply_impulse(vector3*strength-(object_grabbed.linear_velocity*damp), Vector3.ZERO)
	#strength = clamp(vector2.length(), -3.0, 3.0)
	#object_grabbed.apply_impulse(vector2*strength,vector1.normalized())
	object_grabbed.set_angular_damp(7)
	object_grabbed.global_rotation = $GrabPosition3D.global_rotation
	if vector3.length() > 2:
		release()

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseInput.x += event.relative.x
		mouseInput.y += event.relative.y
