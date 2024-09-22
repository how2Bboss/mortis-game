extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player = get_parent().find_parent("Main").find_child("Character")
@export var gravity = -9.8
@export var speed = 4


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var can_move = true
var OnScreen = false
var time = 0

func _on_ready():
	$RigidBody3D.global_position = global_position
	$RigidBody3D.global_rotation = global_rotation
	$RigidBody3D.linear_velocity = Vector3.ZERO
	$RigidBody3D.angular_velocity = Vector3.ZERO

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("F1"):
		_path_to_player()

func _physics_process(delta: float) -> void:
	var destination = navigation_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()

	var path_error = ((player.global_position - navigation_agent.target_position) * Vector3(1.0,0.0,1.0)).length()
	
	time += randi_range(1,3)
	time = fmod(time, 500)
	

	if (player.global_position - global_position).length() < 3.0:
		if (path_error > 1.0) and !OnScreen:
			_path_to_player()
	else:
		if (path_error > 4.0) and !OnScreen:
			_path_to_player()
	
	if not is_on_floor():
		velocity.y += gravity
		
	elif can_move:
		#sets the rigid body to the navigation agents position when it cant be seen
		$RigidBody3D.global_position = global_position
		$RigidBody3D.global_rotation = global_rotation
		$RigidBody3D.linear_velocity = Vector3.ZERO
		$RigidBody3D.angular_velocity = Vector3.ZERO
		$RigidBody3D.set_collision_layer_value(4,false)
		
		navigation_agent.set_velocity(Vector3(direction.x * speed, 0 ,direction.z * speed))
		
		if time == 0:
			$RigidBody3D/AudioStreamPlayer3D.play()
		
		rotation.y = lerp_angle(rotation.y, atan2(-local_destination.x, -local_destination.z) + PI/2, delta * 20.0)

	elif !can_move:
		#sets the navigation agents position to the rigid bodies when it is seen
		global_position = $RigidBody3D.global_position
		velocity.x = 0
		velocity.z = 0
		$RigidBody3D.set_collision_layer_value(4,true)
		navigation_agent.set_velocity_forced(Vector3.ZERO)
		
	if !can_move:
		if $RigidBody3D/FLOOR.is_colliding() and !OnScreen:
			can_move = true
	
	

func _path_to_player():
	if (player.global_position - global_position).length() <= 30:
		var random_position = player.global_position
		navigation_agent.target_position = random_position


func _on_visible_on_screen_enabler_3d_screen_entered() -> void:
	can_move = false
	$RigidBody3D.angular_velocity = Vector3(randf_range(-5.2,5.2),0,randf_range(-5.2,5.2))
	OnScreen = true

func _on_visible_on_screen_enabler_3d_screen_exited() -> void:
	if $RigidBody3D/FLOOR.is_colliding():
		can_move = true
	OnScreen = false
	
	if (player.global_position - navigation_agent.target_position).length() > navigation_agent.target_desired_distance:
		_path_to_player()

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if can_move:
		velocity.x = safe_velocity.x
		velocity.z = safe_velocity.z
		move_and_slide()
