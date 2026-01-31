extends MarginContainer

const BUILDING_ICON = preload("res://assets/mask/happy.png")
const BUILDING_DESTROYED_ICON = preload("res://assets/mask/happy.png")

const BUILDER_ICON = preload("res://assets/mask/happy.png")
const DESTROYER_ICON = preload("res://assets/mask/sad.png")

@onready var _timer_label = $HBoxContainer/TimerLabel
@onready var _builders_count_label = $HBoxContainer/Masks/BuilderMasks
@onready var _destroyers_count_label = $HBoxContainer/Masks/DestroyerMasks
@onready var _strikes_root = $HBoxContainer/Strikes

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_time_label(time_elapsed) -> void:
	var minutes = int(time_elapsed/60)
	var seconds = int(time_elapsed)%60
	var miliseconds = int((time_elapsed - minutes * 60 - seconds)*100)
	_timer_label.text = "%02d:%02d:%02d" % [minutes, seconds, miliseconds]

func set_masks_count(builders: int, destroyers: int) -> void:
	_builders_count_label.text = "%s" % builders
	_destroyers_count_label.text = "%s" % destroyers

func _set_strike_count(count: int) -> void:
	for child in _strikes_root.get_children():
		child.texture = BUILDING_ICON
	if count == 1: _strikes_root.get_child(0).texture = BUILDING_DESTROYED_ICON
	if count == 2: _strikes_root.get_child(1).texture = BUILDING_DESTROYED_ICON
	if count >= 3: _strikes_root.get_child(2).texture = BUILDING_DESTROYED_ICON
		
