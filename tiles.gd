extends RefCounted
class_name Tiles

enum TILETYPES {
	GROUND,
	BUILDING,
	HOLE,
	DIP,
	DEBRIS,
	FOUNTAIN
}

class Tile extends RefCounted:
	var hp: float
	var max_hp: float
	var excess_hp: float = 0.0

	## Gets the index in the Mesh Library the GridMap uses. This ties the Tile data storage class
	## To it's visual representation in the tileset.
	## This index may change according to the tiles parameters, such as it's [code]hp[\code]
	func get_gridmap_index() -> int:
		return -1
	
	## Returns all the possible Mesh Library indices this tile could have.
	## See [code]get_gridmap_index()[\code] for more information.
	static func get_possible_indices() -> Array[int]:
		return [-1]

	## Polymorphic (instance) tile type: use this everywhere you have a tile instance.
	func get_tiletype() -> TILETYPES:
		# Forward to the derived class's static metadata.
		# This avoids duplicating the enum value in two places.
		return tiletype_static()

	## Static tile type metadata: use this when you only have the class (registries).
	static func tiletype_static() -> TILETYPES:
		push_error("Tiles.Tile.tiletype_static() must be overridden by derived class.")
		return TILETYPES.HOLE

	## Run checks to see if the tile should be changed after being damaged.
	## For now, if the tile's own type is returned, no changes should be made.
	func next_tile_damage() -> TILETYPES:
		return get_tiletype()

	## Run checks to see if the tile should be changed after being repaired.
	## For now, if the tile's own type is returned, no changes should be made.
	func next_tile_repair() -> TILETYPES:
		return get_tiletype()


# Tiles
class Building extends Tile:
	func _init() -> void:
		max_hp = 100
		hp = 100

	func get_gridmap_index() -> int:
		if hp >= 80 and excess_hp >= 60:
			return 12
		elif hp >= 80 and excess_hp >= 30:
			return 11
		elif hp >= 80 and excess_hp >= 10:
			return 9
		elif hp <= 33:
			return 4
		elif hp <= 66:
			return 3
		else:
			return 0

	static func get_possible_indices() -> Array[int]:
		return [12, 11, 9, 4, 3, 0]

	static func tiletype_static() -> TILETYPES:
		return TILETYPES.BUILDING


class Ground extends Tile:
	func _init() -> void:
		max_hp = 30
		hp = 30

	func get_gridmap_index() -> int:
		return 1

	static func get_possible_indices() -> Array[int]:
		return [1]

	static func tiletype_static() -> TILETYPES:
		return TILETYPES.GROUND


class Hole extends Tile:
	func _init() -> void:
		max_hp = 50
		hp = 0

	static func tiletype_static() -> TILETYPES:
		return TILETYPES.HOLE


class Debris extends Tile:
	func _init() -> void:
		max_hp = 100
		hp = 20

	func get_gridmap_index() -> int:
		if hp >= 60:
			return 8
		elif hp >= 21:
			return 7
		else:
			return 5

	static func get_possible_indices() -> Array[int]:
		return [8, 7, 5]

	static func tiletype_static() -> TILETYPES:
		return TILETYPES.DEBRIS


class Dip extends Tile:
	func _init() -> void:
		max_hp = 80
		hp = 60

	func get_gridmap_index() -> int:
		return 10

	static func get_possible_indices() -> Array[int]:
		return [10]

	static func tiletype_static() -> TILETYPES:
		return TILETYPES.DIP


class Fountain extends Tile:
	func _init() -> void:
		max_hp = INT_MAX
		hp = INT_MAX

	func get_gridmap_index() -> int:
		return 2

	static func get_possible_indices() -> Array[int]:
		return [2]

	static func tiletype_static() -> TILETYPES:
		return TILETYPES.FOUNTAIN


const TileClasses := [Fountain, Dip, Debris, Ground, Building, Hole]

var _static_index_to_class: Dictionary = {}
var _static_enum_to_class: Dictionary = {}
var _static_built := false


func _build_static_maps() -> void:
	if _static_built:
		return

	_static_index_to_class = {}
	_static_enum_to_class = {}

	for tileClass in TileClasses:
		var t : TILETYPES = tileClass.tiletype_static()
		_static_enum_to_class[t] = tileClass

		for i in tileClass.get_possible_indices():
			_static_index_to_class[i] = t

	_static_built = true


## Helper function to iterate all tileclasses
## Key: MeshLibrary index
## Value: TILETYPES enum
## EG: 0 -> TILETYPES.BUILDING
func getGridmapIndexClassDictionary() -> Dictionary:
	_build_static_maps()
	return _static_index_to_class


func getEnumToClassDictionary() -> Dictionary:
	_build_static_maps()
	return _static_enum_to_class


## Get the Tile Class that corresponds to an enum
func getEnumClass(tiletype: TILETYPES) -> GDScript:
	_build_static_maps()
	return _static_enum_to_class[tiletype]


	
#
#const gridmapIntToEnum = {
	#0: TILETYPES.BUILDING,
	#1: TILETYPES.GROUND,
	#2: TILETYPES.FOUNTAIN,
	#3: TILETYPES.BUILDING,
	#4: TILETYPES.BUILDING,
	#5: TILETYPES.DEBRIS,
	#6: TILETYPES.GROUND,
	#7: TILETYPES.DEBRIS,
	#8: TILETYPES.DEBRIS,
	#9: TILETYPES.BUILDING,
	#10: TILETYPES.DIP,
	#11: TILETYPES.BUILDING,
	#12: TILETYPES.BUILDING
#}

## 2D ARRAY:

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
		var enumtype = getGridmapIndexClassDictionary().get(type, TILETYPES.HOLE)
		match enumtype:
			TILETYPES.BUILDING:
				_tile_storage[pos.x][pos.y] = Building.new()
			TILETYPES.GROUND:
				_tile_storage[pos.x][pos.y] = Ground.new()
			TILETYPES.FOUNTAIN:
				_tile_storage[pos.x][pos.y] = Fountain.new()
			TILETYPES.DEBRIS:
				_tile_storage[pos.x][pos.y] = Debris.new()
			TILETYPES.DIP:
				_tile_storage[pos.x][pos.y] = Dip.new()
			


func get_height():
	return _tile_storage.size()

func get_width():
	return _tile_storage[0].size()
	
func get_building_coords() -> Array:
	var building: Array = []
	for i in range(_tile_storage.size()):
		for j in range(_tile_storage[i].size()):
			if _tile_storage[i][j].get_tiletype() == TILETYPES.BUILDING:
				building.append(Vector2i(i, j))
	
	return building
	
func get_debris_coords() -> Array:
	var debris: Array = []
	for i in range(_tile_storage.size()):
		for j in range(_tile_storage[i].size()):
			if _tile_storage[i][j].get_tiletype() == TILETYPES.DEBRIS:
				debris.append(Vector2i(i, j))
	
	return debris
	
func get_ground_coords() -> Array:
	var ground: Array = []
	for i in range(_tile_storage.size()):
		for j in range(_tile_storage[i].size()):
			if _tile_storage[i][j].get_tiletype() == TILETYPES.GROUND:
				ground.append(Vector2i(i, j))
	
	return ground
	
func get_fountain_coords() -> Array:
	var fountain: Array = []
	for i in range(_tile_storage.size()):
		for j in range(_tile_storage[i].size()):
			if _tile_storage[i][j].get_tiletype() == TILETYPES.FOUNTAIN:
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

func get_tile(coords: Vector2i) -> Tile:
	if _check_bounds(coords):
		return _tile_storage[coords.x][coords.y]

	print("Error, tile not in 2D array %s" % [
		coords
	])
	return Tiles.Hole.new()
	
var tile_rotations = [0,10,16,22]
func set_tile(coords: Vector2i, tile: Tile):
	if not _check_bounds(coords):
		print("Error, tile set not in 2D array %s" % [coords])
		return

	_tile_storage[coords.x][coords.y] = tile

	_gridmap.set_cell_item(to_gridmap(coords), tile.get_gridmap_index(), tile_rotations[randi() % tile_rotations.size()])
