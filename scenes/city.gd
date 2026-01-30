extends Node3D
class_name TileManager

var t_array = Globals.TILE_ARRAY
func _ready() -> void:
	t_array.create_tile_storage($GridMap)
	t_array.set_tile(Vector2i(6, 7), Tiles.Building.new())
	print(t_array._tile_storage.size())
	print(t_array._tile_storage[0].size())
# Called every frame. 'delta' is the elapsed time since the previous frame.

var time = 0.0
func _process(_delta: float) -> void:
	time += _delta
	if time > 1 :
		attack(Vector2i(6,7), 15)
		time = 0
	pass

func attack(pos: Vector2i, damage = 1):
	t_array.get_tile(pos).hp -= damage
	processTile(t_array.get_tile(pos), pos)
	pass

func repair(pos: Vector2i, damage = 1):
	t_array.get_tile(pos).hp += damage
	processTile(t_array.get_tile(pos), pos)
	pass

func processTile(tile: Tiles.Tile, pos : Vector2i):
	if tile.hp < 50 and tile.type == Tiles.TILETYPES.BUILDING:
		$GridMap.set_cell_item(t_array.to_gridmap(pos), 3)
	if tile.hp < 0:
		if tile.type == Tiles.TILETYPES.GROUND:
			t_array.set_tile(pos, Tiles.Hole.new())
			return
		if tile.type == Tiles.TILETYPES.BUILDING or tile.type == Tiles.TILETYPES.DEBRIS:
			t_array.set_tile(pos, Tiles.Ground.new())
			return
		
	pass
