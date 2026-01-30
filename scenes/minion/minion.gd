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

var _free_move_timer: float = 0.0
var _free_move_direction: Vector2 = Vector2(0,0)


func _ready() -> void:
	_pickup_area.body_entered.connect(_pickup_area_entered)
	_unset_mask()

func _physics_process(delta: float) -> void:
	if not _alive: return
	match _current_state:
		STATE.FREE:
			_move_randomly(delta)

func _move_randomly(delta: float) -> void:
	# rotate
	_free_move_timer -= delta
	if _free_move_timer < 0:
		if rng.randf() > free_move_chance:
			_free_move_direction = Vector2(0,0)
		else: 
			var random_angle = rng.randf() * TAU
			_free_move_direction = Vector2(sin(random_angle), cos(random_angle))
			rotation.y = random_angle

		_free_move_timer = rng.randf_range(0.31,1.5) # Technically params
	
	position.x += _free_move_direction.x * delta * free_move_speed
	position.z += _free_move_direction.y * delta * free_move_speed
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

# Signals ===================

func _pickup_area_entered(body) -> void:
	if body is Mask:
		recieve_mask(body)

