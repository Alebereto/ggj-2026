extends RigidBody3D

@onready var city = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node) -> void:
	if body is not GridMap:
		return
	city.attack()
	queue_free()

func _integrate_forces(state: PhysicsDirectBodyState3D):
	# Loop through all current collision contacts
	for i in state.get_contact_count():
		var collider = state.get_contact_collider_object(i)
		
		if collider is GridMap:
			# Get the contact position in Global space
			var contact_pos = state.get_contact_collider_position(i)
			
			var map_coords = Globals.TILE_ARRAY.from_world(contact_pos)
			
			city.attack(map_coords, 20)
			
			queue_free()
			return
