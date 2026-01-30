extends Node3D
class_name TileManager

func _ready() -> void:
	Globals.TILE_CLASS.create_tile_storage($GridMap)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
