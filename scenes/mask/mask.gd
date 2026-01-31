class_name Mask extends CharacterBody3D

const ROTATE_SPEED = 6.0
const SPEED = 5.0

## time before mask can be picked up when dropped
const GRACE_PERIOD = 1.2

const DESTROYER_COLOR: Color = Color.RED
const BUILDER_COLOR: Color = Color.YELLOW

## type of mask
var type: TYPE = TYPE.BUILDER
## true if should vacuum to player
var vacuumed: bool = false
## destination of player throw
var throw_destination = null


var _unpickable_time = 0

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
	if throw_destination: throw_to_destination(throw_destination)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if vacuumed:
		var movement_direction = global_position.direction_to(Globals.player_position)
		velocity = movement_direction * SPEED
		_model_root.rotate_z(ROTATE_SPEED * delta)
		move_and_slide()
	elif throw_destination:
		var movement_direction = global_position.direction_to(throw_destination)
		velocity = movement_direction * SPEED
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

## Makes mask go to node
func get_sucked():
	# dont let thrown masks get sucked mid throw
	if not throw_destination:
		vacuumed = true

func throw_to_destination(destination: Vector3):
	throw_destination = destination

func self_destruct():
	queue_free()

func can_player_pickup() -> bool:
	if throw_destination: return false
	return true

func can_minion_pickup() -> bool:
	if vacuumed: return false
	return true
