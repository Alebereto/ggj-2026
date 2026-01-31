extends Node3D
class_name TileManager

const METEOR_SCENE: PackedScene = preload("res://scenes/meteor/meteor.tscn")

signal building_destroyed

@export var asteroid_timeout:float  = 3.0
@export var building_timeout: float = 30.0
@export var building_weight = 5
var building_count = 0
var t_array = Globals.TILE_ARRAY
var rng = RandomNumberGenerator.new()


func _ready() -> void:
	t_array.create_tile_storage($GridMap)
	t_array.set_tile(Vector2i(6, 7), Tiles.Building.new())
# Called every frame. 'delta' is the elapsed time since the previous frame.

var asteroid_time = 0.0
var building_time = 0.0
func _process(_delta: float) -> void:
	asteroid_time += _delta
	building_time += _delta
	if asteroid_time >= asteroid_timeout:
		summon_meteor()
		asteroid_time = 0.0
	if building_time >= building_timeout:
		summon_building()
		building_time = 0.0
		

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
	
func summon_building():
	var fountains = t_array.get_fountain_coords()
	if fountains.is_empty():
		return
	var height = t_array.get_height()
	var width = t_array.get_width()
	var city_center = Vector2(height/2, width/2)
	var chosen_fountain
	var minDistance = INF
	for fountain in fountains:
		var current_distance = city_center.distance_to(fountain)
		if current_distance < minDistance:
			minDistance = current_distance
			chosen_fountain = fountain
	t_array.set_tile(chosen_fountain, t_array.Building.new())

func attack(pos: Vector2i, damage = 1):
	var tile = t_array.get_tile(pos)
	tile.hp -= damage
	if tile.hp <= 0 and tile.type == Tiles.TILETYPES.BUILDING:
		building_destroyed.emit()
	processTile(tile, pos)
	pass

func repair(pos: Vector2i, damage = 1):
	var max_hp = t_array.get_tile(pos).max_hp
	var tile = t_array.get_tile(pos)
	tile.hp += damage
	if tile.hp > max_hp:
		tile.excess_hp += tile.hp-max_hp
		tile.hp = max_hp
	processTile(tile, pos)
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
