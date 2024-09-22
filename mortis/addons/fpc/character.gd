
# COPYRIGHT Colormatic Studios
# MIT licence
# Quality Godot First Person Controller v2


extends CharacterBody3D

# TODO: Add descriptions for each value


@export_category("Character")
@export var base_speed : float = 3.0
@export var sprint_speed : float = 6.0
@export var crouch_speed : float = 1.0

@export var acceleration : float = 10.0
@export var jump_velocity : float = 4.5
@export var mouse_sensitivity : float = 0.1
@export var immobile : bool = false

@export var max_stamina : float = 100.0
@export var stamina_recover : float = 0.03

@export_group("Nodes")
@export var HEAD : Node3D
@export var CAMERA : Camera3D
@export var COLLISION_MESH : CollisionShape3D

@export_group("Controls")
# We are using UI controls because they are built into Godot Engine so they can be used right away
@export var JUMP : String = "jump"
@export var LEFT : String = "left"
@export var RIGHT : String = "right"
@export var FORWARD : String = "forward"
@export var BACKWARD : String = "back"
@export var PAUSE : String = "ui_cancel"
@export var CROUCH : String = "crouch"
@export var SPRINT : String = "sprint"
@export var INVENTORY : String = "inventory"

# Uncomment if you want full controller support
#@export var LOOK_LEFT : String = "look_left"
#@export var LOOK_RIGHT : String = "look_right"
#@export var LOOK_UP : String = "look_up"
#@export var LOOK_DOWN : String = "look_down"

@export_group("Feature Settings")
@export var jumping_enabled : bool = true
@export var in_air_momentum : bool = true
@export var motion_smoothing : bool = true
@export var sprint_enabled : bool = true
@export var crouch_enabled : bool = true
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode : int = 0
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
@export var dynamic_fov : bool = true
@export var continuous_jumping : bool = true
@export var jump_animation : bool = true
@export var pausing_enabled : bool = true
@export var gravity_enabled : bool = true

@onready var stamina = max_stamina
@onready var flashLight := $Head/FlashLight
@onready var flashLightLerp := $Head/fl_lerp
@onready var flashLightTarget := $Head/fl_target

var speed_multi = 1.0
# Member variables
var speed : float = base_speed
var current_speed : float = 0.0
# States: normal, crouching, sprinting
var state : String = "normal"
var low_ceiling : bool = false # This is for when the cieling is too low and the player needs to crouch.
var was_on_floor : bool = true # Was the player on the floor last frame (for landing animation)

# The reticle should always have a Control node as the root
var RETICLE : Control

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process

# Stores mouse input for rotating the camera in the phyhsics process
var mouseInput : Vector2 = Vector2(0,0)

var paused = false
var inventory = false
var sitting = false
var sittingObj = null

func _ready():
	
	$UI/MarginContainer/BottomLeftHUD/VBoxContainer2/TextureProgressBar.max_value = max_stamina
	#It is safe to comment this line if your game doesn't start with the mouse captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# If the controller is rotated in a certain direction for game design purposes, redirect this rotation into the head.
	HEAD.rotation.y = rotation.y
	rotation.y = 0
	
	check_controls()

func check_controls(): # If you add a control, you might want to add a check for it here.
	# The actions are being disabled so the engine doesn't halt the entire project in debug mode
	if !InputMap.has_action(JUMP):
		push_error("No control mapped for jumping. Please add an input map control. Disabling jump.")
		jumping_enabled = false
	if !InputMap.has_action(LEFT):
		push_error("No control mapped for move left. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(RIGHT):
		push_error("No control mapped for move right. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(FORWARD):
		push_error("No control mapped for move forward. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(BACKWARD):
		push_error("No control mapped for move backward. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(PAUSE):
		push_error("No control mapped for pause. Please add an input map control. Disabling pausing.")
		pausing_enabled = false
	if !InputMap.has_action(CROUCH):
		push_error("No control mapped for crouch. Please add an input map control. Disabling crouching.")
		crouch_enabled = false
	if !InputMap.has_action(SPRINT):
		push_error("No control mapped for sprint. Please add an input map control. Disabling sprinting.")
		sprint_enabled = false

func _physics_process(delta):
	stamina = clamp(stamina, 0, max_stamina)
	$UI/MarginContainer/BottomLeftHUD/VBoxContainer2/TextureProgressBar/StaminaBar.text = str("%0*d" % [3, (stamina)])
	$UI/MarginContainer/BottomLeftHUD/VBoxContainer2/TextureProgressBar.value = stamina
	
	# Gravity
	#gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # If the gravity changes during your game, uncomment this code
	if not is_on_floor() and gravity and gravity_enabled:
		velocity.y -= gravity * delta
	
	handle_jumping()
	
	var input_dir = Vector2.ZERO
	if !immobile && !sitting: # Immobility works by interrupting user input, so other forces can still be applied to the player
		input_dir = Input.get_vector(LEFT, RIGHT, FORWARD, BACKWARD)
	
	var floor = null
	if $ShapeCast3D.is_colliding():
		floor = $ShapeCast3D.get_collider(0)
	
	handle_movement(delta, input_dir)
	
	# The player is not able to stand up if the ceiling is too low
	low_ceiling = $CrouchCeilingDetection.is_colliding()
	
	handle_flashlight()
	
	handle_state(input_dir)
	
	if dynamic_fov: # This may be changed to an AnimationPlayer
		update_camera_fov()
	
	
	if paused == false:
		if state != "sprinting":
			if input_dir:
				stamina += stamina_recover/2.0
			else:
				stamina += stamina_recover
		else:
			stamina += stamina_recover/4.0
		
	
	if sittingObj:
		if abs(sittingObj.global_rotation_degrees.x) > 45:
			sit(sittingObj, sittingObj.get_parent().get_parent(), true)
		elif abs(sittingObj.global_rotation_degrees.z) > 45:
			sit(sittingObj, sittingObj.get_parent().get_parent(), true)
	if sitting:
		if Input.is_action_just_pressed("jump"):
			sit(sittingObj, sittingObj.get_parent().get_parent(), true)
	
	was_on_floor = is_on_floor() # This must always be at the end of physics_process

func handle_jumping():
	if jumping_enabled && !immobile:
		var floor = null
		if $ShapeCast3D.is_colliding():
			floor = $ShapeCast3D.get_collider(0)
		if continuous_jumping: # Hold down the jump button
			if Input.is_action_pressed(JUMP) and is_on_floor() and !low_ceiling:
				velocity.y += jump_velocity # Adding instead of setting so jumping on slopes works properly
		else:
			if Input.is_action_just_pressed(JUMP) and is_on_floor() and !low_ceiling:
				if $Head/ability_grab.object_grabbed != floor:
					velocity.y += jump_velocity
				elif $Head/ability_grab.object_grabbed == null:
					velocity.y += jump_velocity

func handle_movement(delta, input_dir):
	var direction = input_dir.rotated(-HEAD.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	
	if !sitting:
		move_and_slide()
	else:
		global_position = sittingObj.global_position
		#global_rotation = sittingObj.global_rotation
	
	if in_air_momentum:
		if is_on_floor():
			if motion_smoothing:
				velocity.x = lerp(velocity.x, direction.x * speed * speed_multi, acceleration * delta)
				velocity.z = lerp(velocity.z, direction.z * speed * speed_multi, acceleration * delta)
			else:
				velocity.x = direction.x * speed * speed_multi
				velocity.z = direction.z * speed * speed_multi
	else:
		if motion_smoothing:
			velocity.x = lerp(velocity.x, direction.x * speed * speed_multi, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * speed * speed_multi, acceleration * delta)
		else:
			velocity.x = direction.x * speed * speed_multi
			velocity.z = direction.z * speed * speed_multi
	#apply forces to rigidbodies the player collides with
	for i in get_slide_collision_count():
		var collided = get_slide_collision(i).get_collider()
		var hitPoint = get_slide_collision(i).get_position() 
		if collided is RigidBody3D:
			var floor = null
			if $ShapeCast3D.is_colliding():
				floor = $ShapeCast3D.get_collider(0)
			if floor is RigidBody3D and floor == collided:
				collided.apply_force(-Vector3(direction.x * speed, 0.0, direction.z * speed)*3, hitPoint-collided.global_transform.origin)
			else:
				collided.apply_force(Vector3(direction.x * speed, 0.0, direction.z * speed)*3, hitPoint-collided.global_transform.origin)

func handle_state(moving):
	if sprint_enabled:
		if sprint_mode == 0:
			if Input.is_action_pressed(SPRINT) and state != "crouching":
				if moving:
					if state != "sprinting":
						enter_sprint_state()
				else:
					if state == "sprinting":
						enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()
		elif sprint_mode == 1:
			if moving:
				# If the player is holding sprint before moving, handle that cenerio
				if Input.is_action_pressed(SPRINT) and state == "normal":
					enter_sprint_state()
				if Input.is_action_just_pressed(SPRINT):
					match state:
						"normal":
							enter_sprint_state()
						"sprinting":
							enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()
	
	if crouch_enabled:
		if crouch_mode == 0:
			if Input.is_action_pressed(CROUCH) and state != "sprinting":
				if state != "crouching":
					enter_crouch_state()
			elif state == "crouching" and !$CrouchCeilingDetection.is_colliding():
				enter_normal_state()
		elif crouch_mode == 1:
			if Input.is_action_just_pressed(CROUCH):
				match state:
					"normal":
						enter_crouch_state()
					"crouching":
						if !$CrouchCeilingDetection.is_colliding():
							enter_normal_state()
# Any enter state function should only be called once when you want to enter that state, not every frame.
func enter_normal_state():
	#print("entering normal state")
	var prev_state = state
	state = "normal"
	speed = base_speed

func enter_crouch_state():
	#print("entering crouch state")
	var prev_state = state
	state = "crouching"
	speed = crouch_speed

func enter_sprint_state():
	#print("entering sprint state")
	var prev_state = state
	state = "sprinting"
	speed = sprint_speed

func update_camera_fov():
	if state == "sprinting":
		CAMERA.fov = lerp(CAMERA.fov, 85.0, 0.3)
	else:
		CAMERA.fov = lerp(CAMERA.fov, 75.0, 0.3)

func _process(delta):
	handle_head_rotation()

func handle_head_rotation():
	if !(Input.is_action_pressed("rotate") && $Head/ability_grab.object_grabbed != null && $Head/ability_grab.is_heavy == false) && !immobile:
		HEAD.rotation_degrees.y -= mouseInput.x * mouse_sensitivity
		HEAD.rotation_degrees.x -= mouseInput.y * mouse_sensitivity
	
	# Uncomment for controller support
	#var controller_view_rotation = Input.get_vector(LOOK_DOWN, LOOK_UP, LOOK_RIGHT, LOOK_LEFT) * 0.035 # These are inverted because of the nature of 3D rotation.
	#HEAD.rotation.x += controller_view_rotation.x
	#HEAD.rotation.y += controller_view_rotation.y
	
	mouseInput = Vector2(0,0)
	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseInput.x += event.relative.x
		mouseInput.y += event.relative.y

func handle_flashlight():
	
	if flashLightTarget.is_colliding():
		var target:Vector3 = flashLightTarget.get_collision_point()
		flashLightLerp.look_at(target, Vector3.UP)
	else:
		flashLightLerp.look_at($Head.global_position + $Head.global_basis.z * -50)
	
	flashLight.global_rotation.x = lerp_angle(flashLight.global_rotation.x, flashLightLerp.global_rotation.x, 0.1)
	flashLight.global_rotation.y = lerp_angle(flashLight.global_rotation.y, flashLightLerp.global_rotation.y, 0.1)
	flashLight.global_rotation.z = lerp_angle(flashLight.global_rotation.z, flashLightLerp.global_rotation.z, 0.1)
	
	if Input.is_action_just_pressed("flashlight") && !immobile:
		if flashLight.visible == true:
			flashLight.visible = false
			$UI/MarginContainer/BottomLeftHUD/VBoxContainer/FlashLightIcon.disabled = true
		else:
			flashLight.visible = true
			$UI/MarginContainer/BottomLeftHUD/VBoxContainer/FlashLightIcon.disabled = false
	
func stamina_drain(loss):
	stamina -= loss

func sit(ObjSit, dontCollide, forceStand):
	if forceStand:
		velocity = Vector3(0,0,0)
		global_rotation = Vector3.ZERO
		sitting = false
		sittingObj = null
		remove_collision_exception_with(dontCollide)
	else:
		match sitting:
			true:
				velocity = Vector3(0,0,0)
				global_rotation = Vector3.ZERO
				sitting = false
				sittingObj = null
				remove_collision_exception_with(dontCollide)
				
			false:
				velocity = Vector3(0,0,0)
				sitting = true
				sittingObj = ObjSit
				add_collision_exception_with(dontCollide)
				
