extends Node3D

# after MAX_STRIKES buildings destroyed, game over
const MAX_STRIKES = 3

@onready var _player: Player = $Player
@onready var _city = $City
@onready var _minion_manager = $MinionManager
@onready var _mask_manager = $MaskManager
@onready var _ui = $UI

@onready var _cutscene_player: AnimationPlayer = $Cutscene/AnimationPlayer

var timer = 0.0
var current_strikes: int = 0

const START_CUTSCENE_END = 3.0
var _start_cutscene_time: float = 0.0

var world_ending: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()
	_game_begin()

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if world_ending:
		_start_cutscene_time += delta
		if _start_cutscene_time > START_CUTSCENE_END: _game_over()
		return
	if not Globals.during_cutscene:
		timer += delta
	if not world_ending:
		_ui.set_time_label(timer)
	else:
		#TODO: start shaking camera, then zoom out and watch meteor hit then close game
		pass
	
## Called when the game begins
func _game_begin():
	# Play starting cutscene
	Globals.during_cutscene = true
	_ui.hide()
	_cutscene_player.play("starting_cutscene")

func _cutscene_start_end():
	Globals.during_cutscene = false
	$Cutscene/CutsceneCamera.current = false
	_ui.show()

func _connect_signals():
	_player.command_minion.connect(command_minion)
	_player.throw_mask.connect(_mask_manager.throw_mask)
	_player.new_masks_count.connect(_ui.set_masks_count)
	_minion_manager.drop_mask.connect(_mask_manager.drop_mask)
	_city.on_building_destroyed.connect(on_building_destroyed)

## called when the game has ended
func _game_over():
	Globals.during_cutscene = true
	$Cutscene/CutsceneCamera.current = true
	_ui.hide()
	#TODO: switch music
	$Music.stop()
	_player._set_control_mode(Player.CONTROL_MODE.NONE)
	_cutscene_player.play("game_end")

## signal calls ===========================

## Called when building is destroyed in city
func on_building_destroyed():
	current_strikes += 1
	_ui.set_strike_count(current_strikes)
	$BuildingBreak.play()
	if current_strikes >= MAX_STRIKES: world_ending = true

func command_minion(mask_type, global_destination) -> void:
	var grid_pos = _city.world.from_world(global_destination)
	_minion_manager.command_minion(mask_type, grid_pos)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "starting_cutscene":
		_cutscene_start_end()
	if anim_name == "game_end":
		get_tree().quit()
