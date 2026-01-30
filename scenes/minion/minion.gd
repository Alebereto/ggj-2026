class_name Minion extends CharacterBody3D

var rng = RandomNumberGenerator.new()

var _current_state: STATE = STATE.FREE
var _current_mask: Mask.TYPE

var _alive: bool = true

@onready var _mask_model: Node3D = $Mask
@onready var _pickup_area: Area3D = $PickupArea

enum STATE{
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
@export var angle_random = 10

var _follow_waiting = true
var _follow_angle_offset: float = 0.0
var _free_move_timer: float = 0.0
var _free_move_target_dir: Vector2 = Vector2(0,0)
var _free_move_direction: Vector2 = Vector2(0,0)

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
	_free_move_timer -= delta
	# Decide if to walk or not
	if _free_move_timer < 0:
		_follow_waiting = not _follow_waiting
		if _follow_waiting:
			_free_move_timer = rng.randf_range(0.15, 0.67)
		else:
			_free_move_timer = rng.randf_range(1, 2)
			_follow_angle_offset = deg_to_rad(rng.randf_range(-angle_random, angle_random))
		
	
	if _follow_waiting:
		pass
	else:
		var dir = global_pos - global_position
		dir.y = 0
		dir.rotated(Vector3(0,1,0), _follow_angle_offset)
		position += dir.normalized() * delta * speed
		
	
		
	move_and_slide()
	
func _move_randomly(delta: float) -> void:
	var move_time_min = 0.31
	var move_time_max = 1.5
	
	# rotate
	_free_move_timer -= delta
	if _free_move_timer < 0:
		if rng.randf() > free_move_chance:
			_free_move_direction = Vector2(0,0)
			_free_move_target_dir = Vector2(0,0)
		else: 
			var random_angle = rng.randf() * TAU
			_free_move_target_dir = Vector2(sin(random_angle), cos(random_angle))
			rotation.y = random_angle

		_free_move_timer = rng.randf_range(move_time_min, move_time_max) # Technically params
	
	_free_move_direction = lerp(_free_move_direction, _free_move_target_dir, free_move_lerp_strength * delta)
	
	position.x += _free_move_direction.x * delta * free_move_speed
	position.z += _free_move_direction.y * delta * free_move_speed
	move_and_slide()


# MASK LOGIC

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
	_current_state = STATE.FOLLOWING
	if not _alive: return
	if _current_state == STATE.FREE:
		#TODO: make minion react to wind
		return
	#else:
		# TODO: create mask and set it to go to the player
		#_unset_mask()

# Signals ===================

func _pickup_area_entered(body) -> void:
	if body is Mask:
		recieve_mask(body)
