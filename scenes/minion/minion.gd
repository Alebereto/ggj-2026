class_name Minion extends CharacterBody3D

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

func _ready() -> void:
	_pickup_area.body_entered.connect(_pickup_area_entered)
	_unset_mask()

func _physics_process(delta: float) -> void:
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

