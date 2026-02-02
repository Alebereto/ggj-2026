extends Node3D
class_name TileManager

## emits when a building gets destroyed
signal on_building_destroyed

const METEOR_SCENE: PackedScene = preload("res://scenes/meteor/meteor.tscn")

@onready var mask_manager_ref = $"../MaskManager"
signal building_destroyed

@export var asteroid_timeout:float  = 1.5
@export var building_timeout: float = 45.0
@export var building_weight = 15
var b_odds = 0.12
var building_count = 0
var t_array = Globals.TILE_ARRAY
var rng = RandomNumberGenerator.new()


func _ready() -> void:
	t_array.create_tile_storage($GridMap)
# Called every frame. 'delta' is the elapsed time since the previous frame.

var asteroid_time = 0.0
var building_time = 0.0
# var time_global = 0.0
# var ornt = 0
func _process(_delta: float) -> void:
	# time_global += _delta
	# if time_global >= 1.0:
	# 	time_global = 0.0
	# 	for cell in t_array._gridmap.get_used_cells():
	# 		t_array._gridmap.set_cell_item(cell, t_array._gridmap.get_cell_item(cell), ornt)
	# 	ornt += 1
	asteroid_time += _delta
	building_time += _delta
	if asteroid_time >= asteroid_timeout:
		for i in range(rng.randi_range(2,6)):
			summon_meteor()
		asteroid_time = 0.0
	if building_time >= building_timeout:
		summon_building()
		building_time = 0.0
		

func summon_meteor():
	var buildings = t_array.get_building_coords()
	if buildings.is_empty():
		return
	var b_rand = buildings[rng.randi_range(0, buildings.size()-1)]

	var arr_pos = Vector2i(rng.randi_range(0, t_array.get_width()-1), rng.randi_range(0, t_array.get_height()-1))
	if rng.randf() < b_odds:
		arr_pos = b_rand
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
	processExcess(tile, pos)
	processTile(tile, pos)

func repair(pos: Vector2i, damage = 1):
	var max_hp = t_array.get_tile(pos).max_hp
	var tile = t_array.get_tile(pos)
	tile.hp += damage
	if tile.hp > max_hp:
		tile.excess_hp += tile.hp-max_hp
		tile.hp = max_hp
	processTileRepair(tile, pos)

func processTile(tile: Tiles.Tile, pos : Vector2i):
	$GridMap.set_cell_item(t_array.to_gridmap(pos), tile.get_gridmap_index())
	if tile.hp < 0:
		if tile.get_tiletype() == Tiles.TILETYPES.GROUND:
			t_array.set_tile(pos, Tiles.Dip.new())
			return
		if tile.get_tiletype() == Tiles.TILETYPES.DIP:
			t_array.set_tile(pos, Tiles.Hole.new())
			return
			
		if tile.get_tiletype() == Tiles.TILETYPES.BUILDING:
			on_building_destroyed.emit()
			t_array.set_tile(pos, Tiles.Dip.new())
			
			
		if tile.get_tiletype() == Tiles.TILETYPES.DEBRIS:
			var mask_type = Mask.TYPE.BUILDER
			if rng.randi_range(0,2) == 0:
				mask_type= Mask.TYPE.DESTROYER

			if rng.randi_range(0,3) == 0:
				mask_manager_ref.drop_mask(mask_type, t_array.to_world(pos))
			t_array.set_tile(pos, Tiles.Ground.new())
			return
		
	pass

func processExcess(tile: Tiles.Tile, pos : Vector2i):
	if tile.class.get_tiletype() == Tiles.TILETYPES.BUILDING and tile.excess_hp >= 30:
		# debris
		for i in range(int(tile.excess_hp / 9)):
			# spawn debris around
			var a = rng.randi_range(-1, 1)
			var b = rng.randi_range(-1, 1)
			if a == 0 and b == 0:
				continue
			var new_pos = pos + Vector2i(a, b)
			var new_tile = t_array.get_tile(new_pos)
			if new_tile.get_tiletype() == Tiles.TILETYPES.GROUND:
				t_array.set_tile(new_pos, Tiles.Debris.new())
	
	tile.excess_hp = 0.5 * tile.excess_hp

func processTileRepair(tile: Tiles.Tile, pos : Vector2i):
	$GridMap.set_cell_item(t_array.to_gridmap(pos), tile.get_gridmap_index())
	
	if tile.hp >= tile.max_hp:

		if tile.get_tiletype() == Tiles.TILETYPES.DIP:
			t_array.set_tile(pos, Tiles.Ground.new())
			return
			
		if tile.get_tiletype() == Tiles.TILETYPES.HOLE:
			t_array.set_tile(pos, Tiles.Dip.new())
			return
			
	if tile.get_tiletype() == Tiles.TILETYPES.GROUND and tile.excess_hp > 50:
			t_array.set_tile(pos, Tiles.Debris.new())
		
	pass
