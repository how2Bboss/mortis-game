extends Node3D

var img_renderer = preload("res://UI/IMGRENDER.tscn")
@export var Icon : Texture
@export var ObjectName : String
@export var Mass : float
@export var Volume : float

@onready var RigidBody := find_child("RigidBody3D")

var inventoryNode : Node
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#RigidBody.global_position = global_position
	#RigidBody.global_rotation = global_rotation
	
	if Mass == 0:
		Mass = RigidBody.mass
	else:
		RigidBody.mass = Mass
	#if Mass <= 1:
	#	$RigidBody3D.set_collision_layer_value(3, true)
	#	$RigidBody3D.set_collision_layer_value(4, false)
	#else:
	#	$RigidBody3D.set_collision_mask_value(3, false)
	inventoryNode = find_parent("Main").find_child("Character").find_child("INVENTORY")
	if !Icon:
		_render()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	pass

func _store():
	#resets position and sends packed scene to inventory
	RigidBody.global_position = Vector3.ZERO
	self.global_position = Vector3.ZERO
	var scene := PackedScene.new()
	scene.pack(self)
	inventoryNode._add_item(scene, Icon, ObjectName, Mass, Volume)
	queue_free()

func _render():
	var renderer := img_renderer.instantiate()
	var mesh := RigidBody
	var new_mesh := mesh.duplicate()
	add_child(renderer)
	$"IMG_RENDER/VIEWPORT".add_child(new_mesh)
	await RenderingServer.frame_post_draw
	Icon = ImageTexture.new()
	Icon.set_image($"IMG_RENDER/VIEWPORT".get_texture().get_image())
	$"IMG_RENDER".queue_free()
