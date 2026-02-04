extends Node3D
class_name Level

## emits when a building gets destroyed
signal on_building_destroyed

const METEOR_SCENE: PackedScene = preload(Globals.SCENE_UIDS["meteor"])

@export_category("Nodes")
@export var player: Player = null
@export var grid: Grid = null
@export var minion_manager: MinionManager = null
@export var mask_manager: MaskManager = null

@export_category("Level Settings")
@export var asteroid_spawn_height = 10.0
@export var building_weight = 15
@export_range(0,1) var _debris_mask_probability = 0.33
@export_range(0,1) var _builder_mask_probability = 0.5

var b_odds = 0.12
var building_count = 0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_connect_signals()
	grid.create_tile_storage()

func _process(_delta: float) -> void:
	pass

func _connect_signals() -> void:
	minion_manager.drop_mask.connect(mask_manager.drop_mask)
	player.throw_mask.connect(mask_manager.throw_mask)
	player.command_minion.connect(minion_manager.command_minion)


# Public functions
func summon_meteor():
	var buildings = grid.get_building_coords()
	if buildings.is_empty():
		return
	var b_rand = buildings[rng.randi_range(0, buildings.size()-1)]

	var arr_pos = Vector2i(rng.randi_range(0, grid.get_width()-1), rng.randi_range(0, grid.get_height()-1))
	if rng.randf() < b_odds:
		arr_pos = b_rand
	var pos = grid.to_world(arr_pos)
	pos.y = asteroid_spawn_height
	var meteor = METEOR_SCENE.instantiate()
	meteor.position = pos
	add_child(meteor)

func summon_building():
	var fountains = grid.get_fountain_coords()
	if fountains.is_empty():
		return
	var height : int = grid.get_height()
	var width : int = grid.get_width()
	var city_center = Vector2i(int(height/2.0), int(width/2.0))
	var chosen_fountain
	var minDistance = INF
	for fountain in fountains:
		var current_distance = city_center.distance_to(fountain)
		if current_distance < minDistance:
			minDistance = current_distance
			chosen_fountain = fountain
	grid.set_tile(chosen_fountain, Tiles.Building.new())

func attack(pos: Vector2i, damage = 1):
	var tile = grid.get_tile(pos)
	tile.hp -= damage
	attackSpecialCases(tile, pos)
	processTile(tile, pos, tile.next_tile_damage())
	tile.excess_hp = 0.5 * tile.excess_hp

func repair(pos: Vector2i, damage = 1):
	var max_hp = grid.get_tile(pos)._max_hp
	var tile = grid.get_tile(pos)
	tile.hp += damage
	if tile.hp > max_hp:
		tile.excess_hp += tile.hp-max_hp
		tile.hp = max_hp
	processTile(tile, pos, tile.next_tile_repair())

func processTile(tile: Tiles.Tile, pos : Vector2i, new_type : Tiles.TILETYPES):
	if new_type != tile.get_tiletype():
		var new_tile =  Tiles.enumToClass(new_type).new()
		grid.set_tile(pos, new_tile)
	else:
		# In case damage changed the visuals
		grid.update_tile_visuals(pos)


## handles special cases for attacking a tile
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
			var new_tile = grid.get_tile(new_pos)
			if new_tile.get_tiletype() == Tiles.TILETYPES.GROUND:
				grid.set_tile(new_pos, Tiles.Debris.new())

	if tile.get_tiletype() == Tiles.TILETYPES.DEBRIS:
		if tile.hp <= 0:
			# spawn mask with set probability
			var p = rng.randf()
			if p <= _debris_mask_probability:
				# choose mask type
				var mask_type = Mask.TYPE.BUILDER
				p = rng.randf()
				if p <= _builder_mask_probability:
					mask_type= Mask.TYPE.DESTROYER
				# spawn mask
				mask_manager.drop_mask(mask_type, grid.to_world(pos))

