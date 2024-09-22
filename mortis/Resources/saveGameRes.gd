extends Resource
class_name saveGame

#saves player information
@export var player_position : Vector3
@export var player_velocity : Vector3
@export var player_rotation : Vector3
@export var player_stamina : float
@export var player_flashlight_state : bool
@export var player_inventory : Array
@export var player_inventory_icons : Array
@export var player_sitting = false
@export var player_sittingObj = null

#saves world time info
@export var time_current_anim : String
@export var time_anim_pos : float
@export var time_speed : float

#saves objects under the OBJ_HANDLER node
@export var OBJ_HANDLER : Array
