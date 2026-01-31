extends Node3D


@onready var _player: Player = $Player
@onready var _minion_manager = $MinionManager
@onready var _mask_manager = $MaskManager
@onready var _timer_label = $"UI/TimerLabel"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()

# Called every frame. 'delta' is the elapsed time since the previous frame.
var timer = 0.0
func _process(delta: float) -> void:
	timer += delta
	process_timer_label()

func process_timer_label() -> void:
	var minutes = int(timer/60)
	var seconds = int(timer)%60
	var miliseconds = int((timer-minutes*60-seconds)*100)
	_timer_label.text = "%02d:%02d:%02d" % [minutes, seconds, miliseconds]

func _connect_signals():
	_player.command_minion.connect(command_minion)
	_player.throw_mask.connect(_mask_manager.throw_mask)
	_minion_manager.drop_mask.connect(_mask_manager.drop_mask)


## signal calls ===========================

func command_minion(mask_type, global_destination) -> void:
	var grid_pos = Globals.TILE_ARRAY.from_world(global_destination)
	_minion_manager.command_minion(mask_type, grid_pos)
