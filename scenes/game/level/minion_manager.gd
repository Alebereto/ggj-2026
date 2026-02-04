extends Node3D
class_name MinionManager
const MINION_SCENE: PackedScene = preload(Globals.SCENE_UIDS["minion"])

@export var level : Level = null
@onready var _world = level.grid

signal drop_mask(mask_type: Mask.TYPE, global_pos: Vector3, vacuum: bool)

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
var minion_timout = 13.0
var minion_timer = 1000.0

func _process(delta: float) -> void:
	if not Globals.during_cutscene:
		minion_timer += delta
	if minion_timer >= minion_timout:
		var buildings = _world.get_building_coords()
		
		if get_child_count() > buildings.size() * 3:
			return
		for building in buildings:
			var spawn_point = building + Vector2i(rng.randi_range(-1, 2), rng.randi_range(-1, 2))
			if _world.get_tile(spawn_point).get_tiletype() != Tiles.TILETYPES.GROUND:
				continue
			var world_pos = _world.to_world(spawn_point)
			create_minion(world_pos)
		minion_timer = 0.0


func command_minion(mask: Mask.TYPE, global_destination: Vector3):
	var grid_destination: Vector2i = level.grid.from_world(global_destination)
	var target_tile = _world.get_tile(grid_destination)
	if target_tile.get_tiletype() == Tiles.TILETYPES.GROUND:
		return
	var closest_minion = null
	var closest_distance = INF
	for child in get_children():
		if child is Minion:
			if child.get_state() == Minion.STATE.FOLLOWING and child._current_mask == mask:
				var dist_sqrd = (Globals.player_position - child.global_position).length_squared()
				if dist_sqrd <= closest_distance:
					closest_distance = dist_sqrd
					closest_minion = child
	
	if closest_minion == null:
		print(" no followers ")
		return
	
	closest_minion.do_task(grid_destination)
	
	pass

func minion_attack(coords: Vector2i, damage):
	level.attack(coords, damage)
	pass
func minion_repair(coords: Vector2i, damage):
	level.repair(coords, damage)
	pass

func create_minion(pos: Vector3):
	var minion: Minion = MINION_SCENE.instantiate()
	minion.dropped_mask.connect(_drop_mask)
	minion.attack.connect(minion_attack)
	minion.repair.connect(minion_repair)

	minion.world = _world
	minion.position = pos
	add_child(minion)

func _drop_mask(mask_type: Mask.TYPE, global_pos: Vector3, vacuum: bool):
	drop_mask.emit(mask_type, global_pos, vacuum)
