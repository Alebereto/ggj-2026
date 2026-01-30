extends Node3D

signal drop_mask()
signal suck_mask()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func command_minion(mask: Mask.TYPE, grid_destination: Vector2i):
	pass

