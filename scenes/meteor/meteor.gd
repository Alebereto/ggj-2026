extends RigidBody3D

@onready var city = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _integrate_forces(state: PhysicsDirectBodyState3D):
	var t_array = Globals.TILE_ARRAY
	# Loop through all current collision contacts
	for i in state.get_contact_count():
		var collider = state.get_contact_collider_object(i)
		
		if collider is GridMap:
			# Get the contact position in Global space
			var contact_pos = state.get_contact_collider_position(i)
			
			var map_coords = t_array.from_world(contact_pos)
			var tile = t_array.get_tile(map_coords)
			if tile.get_tiletype() == Tiles.TILETYPES.BUILDING:
				city.attack(map_coords, 20)
			elif tile.get_tiletype() == Tiles.TILETYPES.GROUND:
				t_array.set_tile(map_coords, t_array.Debris.new())
			elif tile.get_tiletype() == Tiles.TILETYPES.DEBRIS:
				city.repair(map_coords, 30)
			
			queue_free()
			return
