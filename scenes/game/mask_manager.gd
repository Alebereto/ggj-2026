extends Node3D

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
	mask.position = pos
	mask.vacuumed = vacuum

	add_child(mask)

func throw_mask(mask_type: Mask.TYPE, starting_global_pos: Vector3, destination_global_pos: Vector3):
	var mask: Mask = MASK_SCENE.instantiate()
	mask.type = mask_type
	mask.position = starting_global_pos
	mask.throw_destination = destination_global_pos

	add_child(mask)
