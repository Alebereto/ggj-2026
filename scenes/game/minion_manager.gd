extends Node3D

const MINION_SCENE: PackedScene = preload("res://scenes/minion/minion.tscn")


signal drop_mask(mask_type: Mask.TYPE, global_pos: Vector3, vacuum: bool)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_minion(Vector3(1,0,0))
	create_minion(Vector3(4,0,0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func command_minion(mask: Mask.TYPE, grid_destination: Vector2i):
	var closest_minion = null
	var closest_distance = INF
	for child in get_children():
		if child is Minion:
			if child.get_state() == Minion.STATE.FOLLOWING:
				var dist_sqrd = (Globals.player_position - child.global_position).length_squared()
				if dist_sqrd <= closest_distance:
					closest_distance = dist_sqrd
					closest_minion = child
	
	if closest_minion == null:
		print(" no followers ")
		return
	
	closest_minion.die()
	
		
		
		
	pass

func create_minion(pos: Vector3):
	var minion: Minion = MINION_SCENE.instantiate()
	minion.dropped_mask.connect(_drop_mask)
	minion.position = pos
	add_child(minion)

func _drop_mask(mask_type: Mask.TYPE, global_pos: Vector3, vacuum: bool):
	drop_mask.emit(mask_type, global_pos, vacuum)
