extends RigidBody3D

@onready var city = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _integrate_forces(state: PhysicsDirectBodyState3D):
	var t_array = Globals.TILE_ARRAY
	var buildings = t_array.get_building_coords()
	var ground = t_array.get_ground_coords()
	var debris = t_array.get_debris_coords()
	# Loop through all current collision contacts
	for i in state.get_contact_count():
		var collider = state.get_contact_collider_object(i)
		
		if collider is GridMap:
			# Get the contact position in Global space
			var contact_pos = state.get_contact_collider_position(i)
			
			var map_coords = t_array.from_world(contact_pos)
			if map_coords in buildings:
				city.attack(map_coords, 20)
			elif map_coords in ground:
				t_array.set_tile(map_coords, t_array.Debris.new())
			elif map_coords in debris:
				city.repair(map_coords, 40)
			
			queue_free()
			return
