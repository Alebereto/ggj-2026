extends Node3D


@onready var _player: Player = $Player
@onready var _minion_manager = $MinionManager
@onready var _mask_manager = $MaskManager
@onready var _timer_label = $UI/TimerLabel

var timer = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()
	_game_begin()

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	process_timer_label()

## Called when the game begins
func _game_begin():
	#TODO: starting animation fade in and shit
	pass

func process_timer_label() -> void:
	var minutes = int(timer/60)
	var seconds = int(timer)%60
	var miliseconds = int((timer-minutes*60-seconds)*100)
	_timer_label.text = "%02d:%02d:%02d" % [minutes, seconds, miliseconds]

func _connect_signals():
	_player.command_minion.connect(command_minion)
	_player.throw_mask.connect(_mask_manager.throw_mask)
	_minion_manager.drop_mask.connect(_mask_manager.drop_mask)

## called when the game has ended
func _game_over():
	pass


## signal calls ===========================

func command_minion(mask_type, global_destination) -> void:
	#TODO: convert global destination pos to coordinates
	var grid_pos = Vector2i(0,0)
	_minion_manager.command_minion(mask_type, grid_pos)
