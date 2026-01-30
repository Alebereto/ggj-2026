extends Node3D
class_name TileManager

var t_array = Globals.TILE_ARRAY
func _ready() -> void:
	t_array.create_tile_storage($GridMap)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func attack(pos: Vector2i, damage = 1):
	t_array.get_tile(pos).hp -= damage
	processTile(t_array.get_tile(pos))
	pass

func repair(pos: Vector2i, damage = 1):
	t_array.get_tile(pos).hp += damage
	processTile(t_array.get_tile(pos))
	pass

func processTile(tile: Storage.Tile):
	print(tile)
	pass