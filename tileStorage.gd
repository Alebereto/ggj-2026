extends RefCounted
class_name Storage

enum TILETYPES {
	GROUND,
	BUILDING,
	HOLE,
	DEBRIS
}

class Tile:
	var hp: float
	var max_hp: float

class Building extends Tile:
	func _init() -> void:
		max_hp = 100

class Ground extends Tile:
	pass

class Hole extends Tile:
	pass

class Debris extends Tile:
	pass


const mapToTileTypes = {
	1: TILETYPES.GROUND,
	0: TILETYPES.BUILDING
}
const INT_MAX := 2147483647
const INT_MIN := -2147483648

var tile_storage: Array = []
var min_x := INT_MAX
var max_x := INT_MIN
var min_z := INT_MAX
var max_z := INT_MIN

func create_tile_storage(grid_map: GridMap) -> void:
	tile_storage.clear()
	min_x = INT_MAX
	max_x = INT_MIN
	min_z = INT_MAX
	max_z = INT_MIN

	var cells = grid_map.get_used_cells()
	for cell in cells:
		if cell.x < min_x:
			min_x = cell.x
		if cell.x > max_x:
			max_x = cell.x
		if cell.z < min_z:
			min_z = cell.z
		if cell.z > max_z:
			max_z = cell.z

	for i in range(max_x - min_x + 1):
		tile_storage.append([])
		for j in range(max_z - min_z + 1):
			tile_storage[i].append(Hole.new())

	for cell in cells:
		var type = grid_map.get_cell_item(cell)
		var enumtype = mapToTileTypes.get(type, TILETYPES.HOLE)
		match enumtype:
			TILETYPES.BUILDING:
				set_tile_storage_by_cell(cell, Building.new())
			TILETYPES.GROUND:
				set_tile_storage_by_cell(cell, Ground.new())

func from_gridmap(cell: Vector3i) -> Vector2i:
	return Vector2i(cell.x - min_x, cell.z - min_z)

func to_gridmap(coords: Vector2i) -> Vector3i:
	return Vector3i(coords.x + min_x, 0, coords.y + min_z)

func from_world(pos: Vector3) -> Vector2i:
	return from_gridmap(pos)

func to_world(coords: Vector2i) -> Vector3:
	return to_gridmap(coords)

func set_tile_storage_by_cell(cell: Vector3i, tile: Tile) -> void:
	var pos = from_gridmap(cell)
	tile_storage[pos.x][pos.y] = tile
