class_name Minion extends CharacterBody3D


var rng = RandomNumberGenerator.new()

signal dropped_mask(mask_type: Mask.TYPE, global_pos: Vector3, vacuum: bool)


var _current_state: STATE = STATE.FREE
var _current_mask: Mask.TYPE

var _alive: bool = true

@onready var _mask_model: Node3D = $MaskModel
@onready var _builder_mask_model = $MaskModel/BuilderMaskModel
@onready var _destroyer_mask_model = $MaskModel/DestroyerMaskModel
@onready var _pickup_area: Area3D = $PickupArea

enum STATE {
	FREE,
	FOLLOWING,
	TRAVELING,
	WORKING,
	UNEMPLOYED
}

@export var free_move_chance = 0.5
@export var free_move_speed = 0.8
@export var free_move_lerp_strength = 0.05 * 60
@export var move_to_speed = 1

@export var follow_speed = 2.5
@export var angle_random = 25
@export var follow_lerp_strength = 0.4

var _follow_waiting = true
var _follow_angle_offset: float = 0.0
var _move_timer: float = 0.0
var _move_target_velocity: Vector2 = Vector2(0,0)
var _move_velocity: Vector2 = Vector2(0,0)

func _ready() -> void:
	_pickup_area.body_entered.connect(_pickup_area_entered)
	_unset_mask()

func _physics_process(delta: float) -> void:
	if not _alive: return
	match _current_state:
		STATE.FREE:
			_move_randomly(delta)
		STATE.UNEMPLOYED:
			_move_randomly(delta)
		STATE.FOLLOWING:
			_move_randomly_to(delta, Globals.PLAYER_POSITION)
		STATE.TRAVELING:
			_move_to(delta, Vector3(0,0,0))
			

func _move_to(delta : float, global_pos: Vector3, speed = 2):
	var radius_slow_sqrd = 2.0
	var dir = global_pos - global_position
	var close_lerp = clampf(dir.length_squared(),0, radius_slow_sqrd) / radius_slow_sqrd
	var move_impulse = delta * dir.normalized() * speed * close_lerp
	move_impulse.y = 0
	if move_impulse:
		var angle = atan2(move_impulse.x, move_impulse.z)
		rotation.y = angle
	position += move_impulse
	move_and_slide()
	pass

func _move_randomly_to(delta:float, global_pos: Vector3):
	var speed = follow_speed
	_move_timer -= delta
	# Decide if to walk or not
	if _move_timer < 0:
		_follow_waiting = not _follow_waiting
		if _follow_waiting:
			_move_timer = rng.randf_range(0.15, 0.67)
		else:
			_move_timer = rng.randf_range(1, 2)
			_follow_angle_offset = deg_to_rad(rng.randf_range(-angle_random, angle_random))
		
	
	if _follow_waiting:
		_move_target_velocity = Vector2(0,0)
	else:
		var dir = global_pos - global_position
		dir.y = 0
		dir.rotated(Vector3(0,1,0), _follow_angle_offset)
		dir = dir.normalized() * speed
		_move_target_velocity = Vector2(dir.x, dir.z)
		
	var speed_factor = (1 - (_move_velocity.length() / speed))
	speed_factor = speed_factor * speed_factor
	_move_velocity = lerp(_move_velocity, _move_target_velocity, speed_factor * follow_lerp_strength)
	position += delta * Vector3(_move_velocity.x, 0, _move_velocity.y)
	rotation.y = atan2(_move_velocity.x, _move_velocity.y)
	move_and_slide()
	
func _move_randomly(delta: float) -> void:
	var move_time_min = 0.31
	var move_time_max = 1.5
	
	# rotate
	_move_timer -= delta
	if _move_timer < 0:
		if rng.randf() > free_move_chance:
			_move_velocity = Vector2(0,0)
			_move_target_velocity = Vector2(0,0)
		else: 
			var random_angle = rng.randf() * TAU
			_move_target_velocity = Vector2(sin(random_angle), cos(random_angle))
			rotation.y = random_angle

		_move_timer = rng.randf_range(move_time_min, move_time_max) # Technically params
	
	_move_velocity = lerp(_move_velocity, _move_target_velocity, free_move_lerp_strength * delta)
	
	position.x += _move_velocity.x * delta * free_move_speed
	position.z += _move_velocity.y * delta * free_move_speed
	move_and_slide()


# MASK LOGIC

## drop minion mask
## gets called when minion dies
func _drop_mask():
	#TODO: create mask and make it float
	pass


func die() -> void:
	_alive = false
	dropped_mask.emit(_current_mask, global_position, false)

## sets minion mask type and shows its model
func _set_mask(mask: Mask.TYPE) -> void:
	#TODO: set minion color
	_current_state = STATE.FOLLOWING
	_current_mask = mask
	# set mask color
	match _current_mask:
		Mask.TYPE.BUILDER:
			_builder_mask_model.show()
			_destroyer_mask_model.hide()
		Mask.TYPE.DESTROYER:
			_builder_mask_model.hide()
			_destroyer_mask_model.show()
	_mask_model.show()
	

## unset mask from minion
func _unset_mask() -> void:
	_current_state = STATE.FREE
	_mask_model.hide()

## gets called when minion picks up mask
## gets mask ref
func recieve_mask(mask: Mask):
	if _current_state != STATE.FREE: return
	elif mask and _alive:
		_set_mask(mask.type)
		mask.self_destruct()

## Gets called when the minion gets vacuumed by the player
func get_sucked() -> void:
	_current_state = STATE.FOLLOWING
	if not _alive: return
	if _current_state == STATE.FREE:
		#TODO: make minion react to wind
		return
	else:
		_unset_mask()
		var drop_global_pos = Vector3(global_position.x, global_position.y+0.3, global_position.z)
		dropped_mask.emit(_current_mask, drop_global_pos, true)

# Signals ===================

func _pickup_area_entered(body) -> void:
	if body is Mask:
		if body.can_minion_pickup(): recieve_mask(body)

