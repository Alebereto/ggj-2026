class_name Mask extends RigidBody3D

## time before mask can be picked up when dropped
const GRACE_PERIOD = 1.2

## if true, mask can be picked up by minions
var pickable: bool = true
## type of mask
var type: TYPE
## if true, mask will float toward player
var float_to_player: bool = false

var player_anchor = null
var throw_destination = null


var _unpickable_time = 0

enum TYPE {
	BUILDER,
	DESTROYER
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not float_to_player and not pickable:
		_unpickable_time += delta
		if _unpickable_time >= GRACE_PERIOD: pickable = true

