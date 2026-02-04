extends Node3D
class_name City

## emits when a building gets destroyed
signal on_building_destroyed

const METEOR_SCENE: PackedScene = preload(Globals.SCENE_UIDS["meteor"])

@export var world : Grid = null

@export var mask_manager_ref : MaskManager = null

@export var asteroid_spawn_height = 10.0
@export var asteroid_timeout:float  = 1.5
@export var building_timeout: float = 45.0
@export var building_weight = 15
var b_odds = 0.12
var building_count = 0
var rng = RandomNumberGenerator.new()


func _ready() -> void:
	world.create_tile_storage()
# Called every frame. 'delta' is the elapsed time since the previous frame.

var asteroid_time = 0.0
var building_time = 0.0
# var time_global = 0.0
# var ornt = 0
func _process(_delta: float) -> void:
	# time_global += _delta
	# if time_global >= 1.0:
	# 	time_global = 0.0
	# 	for cell in world._gridmap.get_used_cells():
	# 		world._gridmap.set_cell_item(cell, world._gridmap.get_cell_item(cell), ornt)
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
	var buildings = world.get_building_coords()
	if buildings.is_empty():
		return
	var b_rand = buildings[rng.randi_range(0, buildings.size()-1)]

	var arr_pos = Vector2i(rng.randi_range(0, world.get_width()-1), rng.randi_range(0, world.get_height()-1))
	if rng.randf() < b_odds:
		arr_pos = b_rand
	var pos = world.to_world(arr_pos)	
	pos.y = asteroid_spawn_height
	var meteor = METEOR_SCENE.instantiate()
	meteor.position = pos
	add_child(meteor)
	
func summon_building():
	var fountains = world.get_fountain_coords()
	if fountains.is_empty():
		return
	var height : int = world.get_height()
	var width : int = world.get_width()
	var city_center = Vector2i(int(height/2.0), int(width/2.0))
	var chosen_fountain
	var minDistance = INF
	for fountain in fountains:
		var current_distance = city_center.distance_to(fountain)
		if current_distance < minDistance:
			minDistance = current_distance
			chosen_fountain = fountain
	world.set_tile(chosen_fountain, Tiles.Building.new())

func attack(pos: Vector2i, damage = 1):
	var tile = world.get_tile(pos)
	tile.hp -= damage
	attackSpecialCases(tile, pos)
	processTile(tile, pos, tile.next_tile_damage())
	tile.excess_hp = 0.5 * tile.excess_hp

func repair(pos: Vector2i, damage = 1):
	var max_hp = world.get_tile(pos)._max_hp
	var tile = world.get_tile(pos)
	tile.hp += damage
	if tile.hp > max_hp:
		tile.excess_hp += tile.hp-max_hp
		tile.hp = max_hp
	processTile(tile, pos, tile.next_tile_repair())
	
	
func processTile(tile: Tiles.Tile, pos : Vector2i, new_type : Tiles.TILETYPES):
	if new_type != tile.get_tiletype():
		var new_tile =  Tiles.enumToClass(new_type).new()
		world.set_tile(pos, new_tile)
	else:
		# In case damage changed the visuals
		world.update_tile_visuals(pos)


## 
func attackSpecialCases(tile: Tiles.Tile, pos : Vector2i):
	if tile.get_tiletype() == Tiles.TILETYPES.BUILDING and tile.hp <= 0:
		on_building_destroyed.emit()
		
	if tile.get_tiletype() == Tiles.TILETYPES.BUILDING and tile.excess_hp >= 30:
		# debris
		for i in range(int(tile.excess_hp / 9)):
			# spawn debris around
			var a = rng.randi_range(-1, 1)
			var b = rng.randi_range(-1, 1)
			if a == 0 and b == 0:
				continue
			var new_pos = pos + Vector2i(a, b)
			var new_tile = world.get_tile(new_pos)
			if new_tile.get_tiletype() == Tiles.TILETYPES.GROUND:
				world.set_tile(new_pos, Tiles.Debris.new())

	if tile.get_tiletype() == Tiles.TILETYPES.DEBRIS:
		if tile.hp <= 0:
			var mask_type = Mask.TYPE.BUILDER
			if rng.randi_range(0,2) == 0:
				mask_type= Mask.TYPE.DESTROYER

			if rng.randi_range(0,3) == 0:
				mask_manager_ref.drop_mask(mask_type, world.to_world(pos))
