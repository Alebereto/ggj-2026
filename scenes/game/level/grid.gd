extends GridMap
class_name Grid


const INT_MAX := 2147483647
const INT_MIN := -2147483648

var _gridmap: GridMap = self
var _tile_storage: Array = []

var _min_x := INT_MAX
var _max_x := INT_MIN
var _min_z := INT_MAX
var _max_z := INT_MIN

func create_tile_storage() -> void:
	_tile_storage.clear()
	_min_x = INT_MAX
	_max_x = INT_MIN
	_min_z = INT_MAX
	_max_z = INT_MIN

	var cells = _gridmap.get_used_cells()
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
			_tile_storage[i].append(Tiles.Pit.new())

	for cell in cells:
		var pos = from_gridmap(cell)
		var type = _gridmap.get_cell_item(cell)
		var enumtype = Tiles.getGridmapIndexClassDictionary().get(type, Tiles.TILETYPES.PIT)
		match enumtype:
			Tiles.TILETYPES.BUILDING:
				_tile_storage[pos.x][pos.y] = Tiles.Building.new()
			Tiles.TILETYPES.GROUND:
				_tile_storage[pos.x][pos.y] = Tiles.Ground.new()
			Tiles.TILETYPES.FOUNTAIN:
				_tile_storage[pos.x][pos.y] = Tiles.Fountain.new()
			Tiles.TILETYPES.DEBRIS:
				_tile_storage[pos.x][pos.y] = Tiles.Debris.new()
			Tiles.TILETYPES.HOLE:
				_tile_storage[pos.x][pos.y] = Tiles.Hole.new()
			


func get_height():
	return _tile_storage.size()

func get_width():
	return _tile_storage[0].size()
	
func get_building_coords() -> Array:
	var building: Array = []
	for i in range(_tile_storage.size()):
		for j in range(_tile_storage[i].size()):
			if _tile_storage[i][j].get_tiletype() == Tiles.TILETYPES.BUILDING:
				building.append(Vector2i(i, j))
	
	return building
	
func get_debris_coords() -> Array:
	var debris: Array = []
	for i in range(_tile_storage.size()):
		for j in range(_tile_storage[i].size()):
			if _tile_storage[i][j].get_tiletype() == Tiles.TILETYPES.DEBRIS:
				debris.append(Vector2i(i, j))
	
	return debris
	
func get_ground_coords() -> Array:
	var ground: Array = []
	for i in range(_tile_storage.size()):
		for j in range(_tile_storage[i].size()):
			if _tile_storage[i][j].get_tiletype() == Tiles.TILETYPES.GROUND:
				ground.append(Vector2i(i, j))
	
	return ground
	
func get_fountain_coords() -> Array:
	var fountain: Array = []
	for i in range(_tile_storage.size()):
		for j in range(_tile_storage[i].size()):
			if _tile_storage[i][j].get_tiletype() == Tiles.TILETYPES.FOUNTAIN:
				fountain.append(Vector2i(i, j))
	
	return fountain

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

func get_tile(coords: Vector2i) -> Tiles.Tile:
	if _check_bounds(coords):
		return _tile_storage[coords.x][coords.y]

	print("Error, tile not in 2D array %s" % [
		coords
	])
	return Tiles.Pit.new()

const tile_rotations = [0,10,16,22]
static func random_rotation() -> int:
	return tile_rotations[randi() % tile_rotations.size()]

func set_tile(coords: Vector2i, tile: Tiles.Tile):
	if not _check_bounds(coords):
		print("Error, tile set not in 2D array %s" % [coords])
		return

	_tile_storage[coords.x][coords.y] = tile

	_gridmap.set_cell_item(to_gridmap(coords), tile.get_gridmap_index(), random_rotation())

func update_tile_visuals(coords: Vector2i):
	if not _check_bounds(coords):
		print("Error, tile update not in 2D array %s" % [coords])
		return

	
	var new_tile := get_tile(coords)
	var tile_rotation = _gridmap.get_cell_item_orientation(to_gridmap(coords))
	_gridmap.set_cell_item(to_gridmap(coords), new_tile.get_gridmap_index(), tile_rotation)
