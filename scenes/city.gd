extends Node3D
class_name TileManager

enum TILETYPES {
	GROUND,
	BUILDING,
	HOLE,
	DEBRIS
}

var tile_storage = []
var min_x = INF
var max_x = -INF
var min_z = INF
var max_z = -INF

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_tile_storage()
	print(tile_storage)
	
func create_tile_storage() -> void:
	var cells = $GridMap.get_used_cells()
	for cell in cells:
		if cell.x < min_x:
			min_x = cell.x
		if cell.x > max_x:
			max_x = cell.x
		if cell.z < min_z:
			min_z = cell.z
		if cell.z > max_z:
			max_z = cell.z
	for i in range(max_x-min_x+1):
		tile_storage.append([])
		for j in range(max_z-min_z+1):
			tile_storage[i].append(Hole.new())
	for cell in cells:
		var type = $GridMap.get_cell_item(cell)
		if type == 0:
			set_tile_storage_by_cell(cell, Building.new())
		if type == 1:
			set_tile_storage_by_cell(cell, Ground.new())

func cell_to_array_coords(cell: Vector3) -> Vector2:
	return Vector2(cell.x-min_x, cell.z-min_z)
	
func array_coords_to_cell(coords: Vector2) -> Vector3:
	return Vector3(coords.x+min_x, 0, coords.y+min_z)

func set_tile_storage_by_cell(cell: Vector3, tile: Tile):
	tile_storage[cell.x-min_x][cell.z-min_z] = tile

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
