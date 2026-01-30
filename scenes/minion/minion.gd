class_name Minion extends CharacterBody3D

@export var move_speed = 5.0
@export var rotation_speed = 1.0
@export var min_rotation_time = 0.0
@export var max_rotation_time = 1.0
@export var min_stop_time = 0.0
@export var max_stop_time = 5.0
@export var min_move_time = 2.0
@export var max_move_time = 6.0
var rotation_time
var rotating = false
var moving = true
var direction
var rng = RandomNumberGenerator.new()

var _current_state: STATE = STATE.FREE
var _current_mask: Mask.TYPE

var _alive: bool = true

@onready var _mask_model: Node3D = $Mask

enum STATE{
	FREE,
	FOLLOWING,
	TRAVELING,
	WORKING,
	UNEMPLOYED
}

func _ready() -> void:
	_unset_mask()
	_set_mask(Mask.TYPE.DESTROYER)

func _physics_process(delta: float) -> void:
	_move_randomly(delta)

func _move_randomly(delta: float) -> void:
	# rotate
	var remaining_rotation_time = 0
	if rotating:
		rotation_time -= delta
		if rotation_time <= 0:
			rotation.y += (delta+rotation_time)*direction*rotation_speed
			remaining_rotation_time = -rotation_time
			rotating = false
	if not rotating:
		direction = [1, -1][rng.randi_range(0, 1)]
		rotating = true
		rotation_time = rng.randf_range(min_rotation_time, max_rotation_time)
	rotation.y += (delta-remaining_rotation_time)*direction*rotation_speed
	move_and_slide()

## drop minion mask
## gets called when minion dies
func _drop_mask():
	#TODO: create mask and make it float
	pass

func _set_mask(mask: Mask.TYPE) -> void:
	#TODO: set minion color with mask
	_current_mask = mask
	# set mask color
	match _current_mask:
		Mask.TYPE.BUILDER:
			_mask_model.mesh.material.albedo_color = Color.YELLOW
		Mask.TYPE.DESTROYER:
			_mask_model.mesh.material.albedo_color = Color.RED
	_mask_model.show()
	

func _unset_mask() -> void:
	_current_state = STATE.FREE
	_mask_model.hide()

## gets called when minion picks up mask
## gets mask ref
func recieve_mask(mask: Mask):
	if _current_state != STATE.FREE: return
	elif mask and _alive:
		mask.pickable = false
		_set_mask(mask.type)
		mask.queue_free()

## Gets called when the minion gets vacuumed by the player
func get_sucked() -> void:
	if not _alive: return
	if _current_state == STATE.FREE:
		#TODO: make minion react to wind
		return
	else:
		# TODO: create mask and set it to go to the player
		_unset_mask()

