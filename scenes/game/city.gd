extends Node3D
class_name TileManager

const METEOR_SCENE: PackedScene = preload("res://scenes/meteor/meteor.tscn")

@export var asteroid_timeout:float  = 3.0
@export var building_weight = 5
var t_array = Globals.TILE_ARRAY
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	t_array.create_tile_storage($GridMap)
	t_array.set_tile(Vector2i(6, 7), Tiles.Building.new())
	print(t_array._tile_storage.size())
	print(t_array._tile_storage[0].size())
# Called every frame. 'delta' is the elapsed time since the previous frame.

var time = 0.0
func _process(_delta: float) -> void:
	time += _delta
	if time >= asteroid_timeout:
		summon_meteor()
		time = 0

func summon_meteor():
	var height = t_array.get_height()
	var width = t_array.get_width()
	var buildings = t_array.get_building_coords()
	var x_weights = []
	x_weights.resize(height)
	x_weights.fill(1)
	var y_weights = []
	y_weights.resize(width)
	y_weights.fill(1)
	for building in buildings:
		x_weights[building.x] = building_weight
		y_weights[building.y] = building_weight
	x_weights = PackedFloat32Array(x_weights)
	y_weights = PackedFloat32Array(y_weights)
	var arr_pos = Vector2i(rng.rand_weighted(x_weights), rng.rand_weighted(y_weights))
	var pos = t_array.to_world(arr_pos)	
	pos.y = 5
	var meteor = METEOR_SCENE.instantiate()
	meteor.position = pos
	add_child(meteor)

func attack(pos: Vector2i, damage = 1):
	t_array.get_tile(pos).hp -= damage
	print(t_array.get_tile(pos).hp)
	processTile(t_array.get_tile(pos), pos)
	pass

func repair(pos: Vector2i, damage = 1):
	t_array.get_tile(pos).hp += damage
	processTile(t_array.get_tile(pos), pos)
	pass

func processTile(tile: Tiles.Tile, pos : Vector2i):
	$GridMap.set_cell_item(t_array.to_gridmap(pos), t_array.tileDataToGridmapItem(tile))
	if tile.hp < 0:
		if tile.type == Tiles.TILETYPES.GROUND:
			t_array.set_tile(pos, Tiles.Hole.new())
			return
		if tile.type == Tiles.TILETYPES.BUILDING or tile.type == Tiles.TILETYPES.DEBRIS:
			t_array.set_tile(pos, Tiles.Ground.new())
			return
		
	pass
