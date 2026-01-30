extends Node3D


const MASK_SCENE: PackedScene = preload("res://scenes/mask/mask.tscn")

@onready var _player: Player = $Player
@onready var _player_mask_point: Node3D = _player.find_child("PickupArea")
@onready var _masks_root: Node3D = $MasksRoot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func throw_mask(mask_type: Mask.TYPE, starting_global_pos: Vector3, destination_global_pos: Vector3):
	var mask: Mask = MASK_SCENE.instantiate()
	mask.type = mask_type
	mask.global_position = starting_global_pos
	mask.throw_destination = destination_global_pos

	_masks_root.add_child(mask)

func drop_mask(mask_type: Mask.TYPE, global_pos: Vector3):
	var mask: Mask = MASK_SCENE.instantiate()
	mask.type = mask_type
	mask.global_position = global_pos

	_masks_root.add_child(mask)

func suck_mask(mask_type: Mask.TYPE, global_pos: Vector3):
	var mask: Mask = MASK_SCENE.instantiate()
	mask.type = mask_type
	mask.global_position = global_pos
	mask.player_anchor = _player_mask_point

	_masks_root.add_child(mask)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
