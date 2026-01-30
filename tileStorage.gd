extends RefCounted
class_name Tiles

enum TILETYPES {
	GROUND,
	BUILDING,
	HOLE,
	DEBRIS
}

class Tile extends RefCounted:
	var hp: float
	var max_hp: float
	var type: TILETYPES

class Building extends Tile:
	func _init() -> void:
		type = TILETYPES.BUILDING
		max_hp = 100
		hp = 100

class Ground extends Tile:
	func _init() -> void:
		type = TILETYPES.GROUND
		max_hp = 100
		hp = 100
	pass

class Hole extends Tile:
	func _init() -> void:
		type = TILETYPES.HOLE
		max_hp = 0
		hp = 0
	pass

class Debris extends Tile:
	func _init() -> void:
		type = TILETYPES.DEBRIS
		max_hp = 50
		hp = 50
	pass


const gridmapIntToEnum = {
	1: TILETYPES.GROUND,
	0: TILETYPES.BUILDING
}

const enumToGridmapInt ={
   TILETYPES.GROUND : 1,
	TILETYPES.BUILDING  : 0,
	TILETYPES.HOLE : -1,
	TILETYPES.DEBRIS : 2
}

const INT_MAX := 2147483647
const INT_MIN := -2147483648

var _gridmap = GridMap.new()
var _tile_storage: Array = []
var _min_x := INT_MAX
var _max_x := INT_MIN
var _min_z := INT_MAX
var _max_z := INT_MIN

func create_tile_storage(grid_map: GridMap) -> void:
	_gridmap = grid_map
	_tile_storage.clear()
	_min_x = INT_MAX
	_max_x = INT_MIN
	_min_z = INT_MAX
	_max_z = INT_MIN

	var cells = grid_map.get_used_cells()
	for cell in cells:
		if cell.x < _min_x:
			_min_x = cell.x
		if cell.x > _max_x:
			_max_x = cell.x
		if cell.z < _min_z:
			_min_z = cell.z
		if cell.z > _max_z:
			_max_z = cell.z

	for i in range(_max_x - _min_x + 1):
		_tile_storage.append([])
		for j in range(_max_z - _min_z + 1):
			_tile_storage[i].append(Hole.new())

	for cell in cells:
		var pos = from_gridmap(cell)

		var type = grid_map.get_cell_item(cell)
		var enumtype = gridmapIntToEnum.get(type, TILETYPES.HOLE)
		match enumtype:
			TILETYPES.BUILDING:
				_tile_storage[pos.x][pos.y] = Building.new()
			TILETYPES.GROUND:
				_tile_storage[pos.x][pos.y] = Ground.new()

func from_gridmap(cell: Vector3i) -> Vector2i:
	return Vector2i(cell.x - _min_x, cell.z - _min_z)

func to_gridmap(coords: Vector2i) -> Vector3i:
	return Vector3i(coords.x + _min_x, 0, coords.y + _min_z)

func from_world(pos: Vector3) -> Vector2i:
	# TODO: do
	return from_gridmap(pos)

func to_world(coords: Vector2i) -> Vector3:
	#TODO: do
	return to_gridmap(coords)

func _check_bounds(offset: Vector2i) -> bool:
	return (
		offset.x >= 0
		and offset.y >= 0
		and offset.x < _tile_storage.size()
		and offset.y < _tile_storage[0].size()
	)

func get_tile(coords: Vector2i) -> Tile:
	if _check_bounds(coords):
		return _tile_storage[coords.x][coords.y]

	print("Error, tile not in 2D array %s" % [
		coords
	])
	return Tiles.Hole.new()
	
func set_tile(coords: Vector2i, tile: Tile):
	if not _check_bounds(coords):
		print("Error, tile set not in 2D array %s" % [coords])
		return
	_tile_storage[coords.x][coords.y] = tile
	_gridmap.set_cell_item(to_gridmap(coords), enumToGridmapInt[tile.type])
