extends RefCounted
class_name Tiles

enum TILETYPES {
	GROUND,
	BUILDING,
	HOLE,
	DIP,
	DEBRIS
}

class Tile extends RefCounted:
	var hp: float
	var max_hp: float
	var excess_hp: float = 0.0
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
		max_hp = 100
		hp = 20
	pass
	
class Dip extends Tile:
	func _init() -> void:
		type = TILETYPES.DIP
		max_hp = 50
		hp = 50
	pass


const gridmapIntToEnum = {
	1: TILETYPES.GROUND,
	0: TILETYPES.BUILDING,
	3: TILETYPES.BUILDING,
	4: TILETYPES.BUILDING,
	5: TILETYPES.DIP,
	6: TILETYPES.GROUND
}

func tileDataToGridmapItem(tile) -> int:
	var hp = tile.hp
	var excess_hp = tile.excess_hp
	match tile.type:
		TILETYPES.GROUND:
			return 1
		TILETYPES.BUILDING:
			if hp <= 33:
				return 4
			elif hp <= 66:
				return 3
			else:
				return 0
		TILETYPES.DEBRIS:
			if hp >= 60:
				return 8
			else:
				return 7
		TILETYPES.DIP:
			return 5
	return -1

const INT_MAX := 2147483647
const INT_MIN := -2147483648

var _gridmap = GridMap.new()
var _tile_storage: Array = []
var _coords = {
	TILETYPES.GROUND: [],
	TILETYPES.BUILDING: [],
	TILETYPES.DEBRIS: []
}
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
		_coords[enumtype].append(pos)

func get_height():
	return _tile_storage.size()

func get_width():
	return _tile_storage[0].size()
	
func get_building_coords() -> Array:
	return _coords[TILETYPES.BUILDING].duplicate(true)
	
func get_debris_coords() -> Array:
	return _coords[TILETYPES.DEBRIS].duplicate(true)
	
func get_ground_coords() -> Array:
	return _coords[TILETYPES.GROUND].duplicate(true)

## gets gridmap coords, returns array coords
func from_gridmap(cell: Vector3i) -> Vector2i:
	return Vector2i(cell.x - _min_x, cell.z - _min_z)

## gets array coords, returns grid map coords
func to_gridmap(coords: Vector2i) -> Vector3i:
	return Vector3i(coords.x + _min_x, 0, coords.y + _min_z)

## gets pos in wrold coordinates, returns coords in array
func from_world(pos: Vector3) -> Vector2i:
	return from_gridmap(_gridmap.local_to_map(_gridmap.to_local(pos)))

## gets coords in array, returns world coordinates
func to_world(coords: Vector2i) -> Vector3:
	return _gridmap.to_global(_gridmap.map_to_local(to_gridmap(coords)))

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
	var old_type = _tile_storage[coords.x][coords.y].type
	_coords[old_type].erase(coords)
	_tile_storage[coords.x][coords.y] = tile
	_coords[tile.type].append(coords)
	_gridmap.set_cell_item(to_gridmap(coords), tileDataToGridmapItem(tile))
