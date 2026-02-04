extends RefCounted
class_name Tiles

enum TILETYPES {
	GROUND,
	BUILDING,
	PIT,
	HOLE,
	DEBRIS,
	FOUNTAIN
}

static func getEnumName(tiletype: TILETYPES) -> String:
	match tiletype:
		TILETYPES.GROUND:
			return "GROUND"
		TILETYPES.BUILDING:
			return "BUILDING"
		TILETYPES.PIT:
			return "PIT"
		TILETYPES.HOLE:
			return "HOLE"
		TILETYPES.DEBRIS:
			return "DEBRIS"
		TILETYPES.FOUNTAIN:
			return "FOUNTAIN"
		_:
			return "UNKNOWN"
			

class Tile extends RefCounted:
	var hp: float
	var _max_hp: float = 0.0
	var excess_hp: float = 0.0

	## Gets the index in the Mesh Library the GridMap uses. This ties the Tile data storage class
	## To it's visual representation in the tileset.
	## This index may change according to the tiles parameters, such as it's [code]hp[/code]
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
		return TILETYPES.PIT

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
		_max_hp = 100
		hp = 100

	func next_tile_damage() -> TILETYPES:
		if hp <= 0:
			return TILETYPES.HOLE
		return TILETYPES.BUILDING

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
		_max_hp = 30
		hp = 30

	func next_tile_repair() -> TILETYPES:
		if excess_hp >= 50:
			return TILETYPES.DEBRIS
		return TILETYPES.GROUND

	func get_gridmap_index() -> int:					return 1
	static func get_possible_indices() -> Array[int]:	return [1, 6]
	static func tiletype_static() -> TILETYPES:			return TILETYPES.GROUND


class Pit extends Tile:
	func _init() -> void:
		_max_hp = 50
		hp = 0
	
	func next_tile_repair() -> TILETYPES:
		if hp >= _max_hp:
			return TILETYPES.HOLE
		return TILETYPES.PIT

	func get_gridmap_index() -> int:					return -1
	static func get_possible_indices() -> Array[int]:	return [-1]
	static func tiletype_static() -> TILETYPES:			return TILETYPES.PIT

class Debris extends Tile:
	func _init() -> void:
		_max_hp = 100
		hp = 20

	func next_tile_damage() -> TILETYPES:
		if hp <= 0:
			return TILETYPES.GROUND
		return TILETYPES.DEBRIS

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


class Hole extends Tile:
	func _init() -> void:
		_max_hp = 80
		hp = 60

	func next_tile_repair() -> TILETYPES:
		if hp >= _max_hp:
			return TILETYPES.GROUND
		return TILETYPES.HOLE	
	
	func next_tile_damage() -> TILETYPES:
		if hp <= 0:
			return TILETYPES.PIT
		return TILETYPES.HOLE	

	func get_gridmap_index() -> int:					return 10
	static func get_possible_indices() -> Array[int]:	return [10]
	static func tiletype_static() -> TILETYPES:			return TILETYPES.HOLE


class Fountain extends Tile:
	func _init() -> void:
		_max_hp = 100000
		hp = 100000

	func get_gridmap_index() -> int:					return 2
	static func get_possible_indices() -> Array[int]:	return [2]
	static func tiletype_static() -> TILETYPES:			return TILETYPES.FOUNTAIN


const TileClasses := [Fountain, Hole, Debris, Ground, Building, Pit]

static var _static_index_to_class: Dictionary = {}
static var _static_enum_to_class: Dictionary = {}
static var _static_built := false


static func _build_static_maps() -> void:
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
static func getGridmapIndexClassDictionary() -> Dictionary:
	_build_static_maps()
	return _static_index_to_class

## Key: tiletype enum
## Value: Tile class
static func getEnumToClassDictionary() -> Dictionary:
	_build_static_maps()
	return _static_enum_to_class


## Get the Tile Class that corresponds to an enum
static func enumToClass(tiletype: TILETYPES) -> GDScript:
	_build_static_maps()
	return _static_enum_to_class[tiletype]
