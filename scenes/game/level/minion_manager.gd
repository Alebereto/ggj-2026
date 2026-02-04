extends Node3D
class_name MinionManager
const MINION_SCENE: PackedScene = preload(Globals.SCENE_UIDS["minion"])

@export var level : Level = null
@onready var _world = level.grid

signal drop_mask(mask_type: Mask.TYPE, global_pos: Vector3, vacuum: bool)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

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

func minion_attack(coords: Vector2i, damage):
	level.attack(coords, damage)

func minion_repair(coords: Vector2i, damage):
	level.repair(coords, damage)

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
