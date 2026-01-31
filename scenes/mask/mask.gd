class_name Mask extends CharacterBody3D

const ROTATE_SPEED = 6.0
const IDLE_ROTATE_SPEED = 5.0
const SPEED = 5.0

const AIR_TIME = 1.2

## time before mask can be picked up when dropped
const GRACE_PERIOD = 1.2

const DESTROYER_COLOR: Color = Color.RED
const BUILDER_COLOR: Color = Color.YELLOW

enum STATE {
	DROPPED,
	VACUUMED,
	THROWN
}

var current_state: STATE = STATE.DROPPED

## type of mask
var type: TYPE = TYPE.BUILDER
## destination of player throw
var throw_destination: Vector3 = Vector3.ZERO
var _throw_direction: Vector3 = Vector3.ZERO

# current air time
var _thrown_time: float = 0.0

@onready var _model_root: Node3D = $Model
@onready var _builder_mask_model: MeshInstance3D = $Model/BuilderMaskModel
@onready var _destroyer_mask_model: MeshInstance3D = $Model/DestroyerMaskModel

enum TYPE {
	BUILDER,
	DESTROYER
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_mask_model()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	match current_state:
		STATE.DROPPED:
			pass
		STATE.VACUUMED:
			# move toward player and spin
			var movement_direction = global_position.direction_to(Globals.player_position)
			velocity = movement_direction * SPEED
			_model_root.rotate_z(ROTATE_SPEED * delta)
			move_and_slide()
		STATE.THROWN:
			_thrown_time += delta
			if _thrown_time >= AIR_TIME:
				drop()
				return
			if _throw_direction == Vector3.ZERO: _throw_direction = global_position.direction_to(throw_destination)
			velocity = _throw_direction * SPEED
			_model_root.rotate_z(ROTATE_SPEED * delta)
			move_and_slide()
	# _unpickable_time += delta
	# if _unpickable_time >= GRACE_PERIOD: print("YIPEE")


func _set_mask_model() -> void:
	match type:
		TYPE.BUILDER:
			_destroyer_mask_model.hide()
			_builder_mask_model.show()
		TYPE.DESTROYER:
			_destroyer_mask_model.show()
			_builder_mask_model.hide()


func drop() -> void:
	#TODO: set height?
	current_state = STATE.DROPPED

## gets called when being vacuumed
func get_sucked():
	# dont let thrown masks get sucked mid throw
	if not current_state == STATE.THROWN and not current_state == STATE.VACUUMED:
		#TODO: maybe more stuff on initial vacuum
		current_state = STATE.VACUUMED

func throw_to_destination(destination: Vector3):
	current_state = STATE.THROWN
	throw_destination = destination
	_thrown_time = 0.0

func self_destruct():
	queue_free()


## returns true if player can pickup mask
func can_player_pickup() -> bool:
	if current_state == STATE.THROWN: return false
	return true

func can_minion_pickup() -> bool:
	if current_state == STATE.VACUUMED: return false
	return true
