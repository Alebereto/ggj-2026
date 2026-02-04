extends Node3D
class_name MaskManager

const MASK_SCENE: PackedScene = preload("res://scenes/mask/mask.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func drop_mask(mask_type: Mask.TYPE, pos: Vector3, vacuum: bool = false):
	var mask: Mask = MASK_SCENE.instantiate()
	mask.type = mask_type
	if vacuum: mask.current_state = Mask.STATE.VACUUMED
	else: mask.current_state = Mask.STATE.DROPPED
	mask.position = pos

	add_child(mask)

func throw_mask(mask_type: Mask.TYPE, starting_global_pos: Vector3, destination_global_pos: Vector3):
	var mask: Mask = MASK_SCENE.instantiate()
	mask.type = mask_type
	mask.current_state = Mask.STATE.THROWN
	mask.position = starting_global_pos
	mask.throw_destination = destination_global_pos

	add_child(mask)
