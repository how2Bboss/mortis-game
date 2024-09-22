extends Control

var playerNode = null
var reticleNode = null
var inventoryNode = null
var itemSelected = null
var objHandlerNode = null
var playerGrab = null
var items = []
var itemsIcons = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	objHandlerNode = find_parent("Main").find_child("OBJ_HANDLER")
	reticleNode = $"../ReticleCenter"
	playerNode = $"../../"
	inventoryNode = $TabContainer/Inventory/InventoryVbox/ListsHbox/Item
	playerGrab = $"../../Head/ability_grab/GrabPosition3D"
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	visible = playerNode.inventory
	reticleNode.visible = !playerNode.inventory


func _on_equip_pressed() -> void:
	pass # Replace with function body.
	

func _remove_item(index):
	items.remove_at(index)
	itemsIcons.remove_at(index)
	inventoryNode.remove_item(index)
	inventoryNode.deselect_all()
	itemSelected = null
	$TabContainer/Inventory/InventoryVbox/Buttons/Equip.set_disabled(true)
	$TabContainer/Inventory/InventoryVbox/Buttons/Drop.set_disabled(true)

func _add_item(scene, Icon, ObjectName, Mass, Volume):
	var object = [scene,Icon,ObjectName,Mass,Volume]
	items.append(object)
	itemsIcons.append([ObjectName, Icon])
	inventoryNode.add_item(ObjectName, Icon)
	

func _on_drop_pressed() -> void:
	if itemSelected != null:
		var spawn = items[itemSelected][0]
		var new_object = spawn.instantiate()
		objHandlerNode.add_child(new_object)
		var objectRidid = new_object.find_child("RigidBody3D")
		new_object.global_position = Vector3.ZERO
		new_object.global_rotation = Vector3.ZERO
		if $"../../Head/ability_place".is_colliding():
			objectRidid.global_position = $"../../Head/ability_place".get_collision_point() + $"../../Head/ability_place".get_collision_normal()*0.6
		else:
			objectRidid.global_position = playerGrab.global_position
		objectRidid.global_rotation = playerGrab.global_rotation
		objectRidid.linear_velocity = Vector3.ZERO
		objectRidid.angular_velocity = Vector3.ZERO
		_remove_item(itemSelected)


func _on_item_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
	inventoryNode.deselect_all()
	itemSelected = null
	$TabContainer/Inventory/InventoryVbox/Buttons/Equip.set_disabled(true)
	$TabContainer/Inventory/InventoryVbox/Buttons/Drop.set_disabled(true)



func _on_item_item_selected(index: int) -> void:
	itemSelected = index
	$TabContainer/Inventory/InventoryVbox/Buttons/Equip.set_disabled(false)
	$TabContainer/Inventory/InventoryVbox/Buttons/Drop.set_disabled(false)


func _on_hidden() -> void:
	inventoryNode.deselect_all()
	itemSelected = null
	$TabContainer/Inventory/InventoryVbox/Buttons/Equip.set_disabled(true)
	$TabContainer/Inventory/InventoryVbox/Buttons/Drop.set_disabled(true)
