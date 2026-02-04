extends Node

# after MAX_STRIKES buildings destroyed, game over
const MAX_STRIKES = 3

@export_category("Nodes")
@export var _level: Level = null
@export var _ui : UI = null
@export var _cutscene_camera : Camera3D = null
@export var _music : AudioStreamPlayer = null
@export var _cutscene_player: AnimationPlayer = null

@export_category("Game Settings")
@export var asteroid_timeout:float  = 1.5
@export var building_timeout: float = 45.0
var asteroid_time = 0.0
var building_time = 0.0

@onready var _player: Player = _level.player

## game time elapsed
var timer = 0.0
var current_strikes: int = 0

## time after game over when game over cutscene plays
const WORLD_END_TIME = 3.0
var _world_end_timer: float = 0.0

var world_ending: bool = false


var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()
	_game_begin()

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if world_ending:
		_world_end_timer += delta
		if _world_end_timer > WORLD_END_TIME: _game_over()
		return
	if not Globals.during_cutscene:
		timer += delta
	if not world_ending:
		_ui.set_time_label(timer)

	# time_global += _delta
	# if time_global >= 1.0:
	# 	time_global = 0.0
	# 	for cell in world._gridmap.get_used_cells():
	# 		world._gridmap.set_cell_item(cell, world._gridmap.get_cell_item(cell), ornt)
	# 	ornt += 1
	asteroid_time += delta
	building_time += delta
	if asteroid_time >= asteroid_timeout:
		for i in range(rng.randi_range(2,6)):
			_level.summon_meteor()
		asteroid_time = 0.0
	if building_time >= building_timeout:
		_level.summon_building()
		building_time = 0.0

func _connect_signals():
	_player.new_masks_count.connect(_ui.set_masks_count)
	_level.on_building_destroyed.connect(on_building_destroyed)
	_cutscene_player.animation_finished.connect(_on_animation_player_animation_finished)

## Called when the game begins
func _game_begin():
	# Play starting cutscene
	Globals.during_cutscene = true
	_ui.hide()
	_cutscene_player.play("starting_cutscene")

func _cutscene_start_end():
	Globals.during_cutscene = false
	_cutscene_camera.current = false
	_ui.show()

## called when the game has ended
func _game_over():
	Globals.during_cutscene = true
	_cutscene_camera.current = true
	_ui.hide()
	#TODO: switch music
	_music.stop()
	_player._set_control_mode(Player.CONTROL_MODE.NONE)
	_cutscene_player.play("game_end")

## signal calls ===========================

## Called when building is destroyed in city
func on_building_destroyed():
	current_strikes += 1
	_ui.set_strike_count(current_strikes)
	$BuildingBreak.play()
	if current_strikes >= MAX_STRIKES: world_ending = true

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "starting_cutscene":
		_cutscene_start_end()
	if anim_name == "game_end":
		get_tree().quit()
