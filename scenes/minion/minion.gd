class_name Minion extends CharacterBody3D


var rng = RandomNumberGenerator.new()

signal dropped_mask(mask_type: Mask.TYPE, global_pos: Vector3, vacuum: bool)
signal attack(coords: Vector2i, damage)
signal repair(coords: Vector2i, damage)



var _current_state: STATE = STATE.FREE
var _current_mask: Mask.TYPE
var _current_task_2d: Vector2i
var _current_task_3d: Vector3


func get_state() -> STATE:
	return _current_state

var _alive: bool = true


@onready var _pickup_area: Area3D = $PickupArea

@onready var _animation_player: AnimationPlayer = $MinionModel/AnimationPlayer

#Models
@onready var _mask_model: Node3D = $MaskModel
@onready var _builder_mask_model = $MaskModel/BuilderMaskModel
@onready var _destroyer_mask_model = $MaskModel/DestroyerMaskModel

# Sounds
@onready var _death_sound: AudioStreamPlayer3D = $Sounds/Death

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

@export var working_damage_cooldown = 1.5
@export var working_repair_cooldown = 0.3
@export var working_damage = 5
@export var working_repair_damage = 1


var _work_timer = 0.0

var _follow_waiting = true
var _follow_angle_offset: float = 0.0
var _move_timer: float = 0.0
var _move_target_velocity: Vector2 = Vector2(0,0)
var _move_velocity: Vector2 = Vector2(0,0)

func reset_move_params():
	_move_timer = 0.0
	_move_target_velocity = Vector2(0,0)
	_move_velocity = Vector2(0,0)

# how much time until the minion dies :(
var _time_to_death = 60.0 # TODO: random 100 - 200
# time corpse remains
var _corpse_time = 3.0


func _ready() -> void:
	_pickup_area.body_entered.connect(_pickup_area_entered)
	_unset_mask()

func _physics_process(delta: float) -> void:
	if _alive:
		_time_to_death -= 0.5 * delta
		if _time_to_death <= 0: die()
		
		# Movement
		if not _alive: return
		match _current_state:
			STATE.FREE:
				_move_randomly(delta)
			STATE.UNEMPLOYED:
				_move_randomly(delta)
			STATE.FOLLOWING:
				_move_randomly_to(delta, Globals.player_position)
			STATE.TRAVELING:
				_move_to(delta, _current_task_3d)
				attempt_start_working()
			STATE.WORKING:
				_time_to_death -= 0.8 * delta
				reset_move_params()
				velocity = Vector3(0,0,0)
				working_loop(delta)
				pass
		_walk_animation()
	else:
		_corpse_time -= delta
		#TODO: a second before deletion call poof
		if _corpse_time <= 0:
			queue_free()

func attempt_start_working():
	var error := -(global_position - _current_task_3d)
	if error.length_squared() < 3:
		_current_state = STATE.WORKING


func working_loop(delta : float):
	_work_timer -= delta
	if _work_timer <= 0:
		do_work()
		if _current_mask == Mask.TYPE.BUILDER:
			_work_timer = working_repair_cooldown
		elif _current_mask == Mask.TYPE.DESTROYER:
			_work_timer = working_damage_cooldown
func do_work():
	if _current_mask == Mask.TYPE.BUILDER:
		repair.emit(_current_task_2d, working_repair_damage)
		_animation_player.stop()
		if Globals.rng.randi_range(0,1) == 0:
			_animation_player.play("interact-right")
		else:
			_animation_player.play("interact-left")
		_animation_player.advance(0)
	elif _current_mask == Mask.TYPE.DESTROYER:
		attack.emit(_current_task_2d, working_damage)
		_animation_player.stop()
		_animation_player.play("attack-melee-right")
		_animation_player.advance(0)
	
	
	


## if minion is fast enough, play walk animaiton
func _walk_animation() -> void:
	if velocity.length() > 0.5:
		_animation_player.play("walk")

func _move_to(delta : float, global_pos: Vector3, speed = 2):
	var radius_slow_sqrd = 2.0
	var dir = global_pos - global_position
	var close_lerp = clampf(dir.length_squared(),0, radius_slow_sqrd) / radius_slow_sqrd
	var move_impulse = dir.normalized() * speed * close_lerp
	move_impulse.y = 0
	if move_impulse:
		var angle = atan2(move_impulse.x, move_impulse.z)
		rotation.y = angle
	velocity = move_impulse
	move_and_slide()

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
		var dir = (global_pos - global_position)
		dir -= 0.8 * dir.normalized()
		dir.y = 0
		dir.rotated(Vector3(0,1,0), _follow_angle_offset)
		dir = dir.normalized() * speed * clampf(dir.length_squared(), 0, 1)
		_move_target_velocity = Vector2(dir.x, dir.z)
		
	var speed_factor = (1 - (_move_velocity.length() / speed))
	speed_factor = speed_factor * speed_factor
	_move_velocity = lerp(_move_velocity, _move_target_velocity, speed_factor * follow_lerp_strength)
	velocity = Vector3(_move_velocity.x, 0, _move_velocity.y)
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
	
	velocity.x = _move_velocity.x * free_move_speed
	velocity.z = _move_velocity.y * free_move_speed
	move_and_slide()


# MASK LOGIC


func die() -> void:
	_alive = false
	if _current_state != STATE.FREE:
		dropped_mask.emit(_current_mask, global_position, false)
	_unset_mask()
	_death_sound.play()
	_animation_player.play("die")

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
	
func do_task(vec : Vector2i):
	_current_state = STATE.TRAVELING
	_current_task_2d = vec
	_current_task_3d = Globals.TILE_ARRAY.to_world(vec)

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
