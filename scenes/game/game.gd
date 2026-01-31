extends Node3D


@onready var _player: Player = $Player
@onready var _minion_manager = $MinionManager
@onready var _mask_manager = $MaskManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _connect_signals():
	_player.command_minion.connect(command_minion)
	_player.throw_mask.connect(_mask_manager.throw_mask)
	_minion_manager.drop_mask.connect(_mask_manager.drop_mask)


## signal calls ===========================

func command_minion(mask_type, global_destination) -> void:
	#TODO: convert global destination pos to coordinates
	var grid_pos = Vector2i(0,0)
	_minion_manager.command_minion(mask_type, grid_pos)

