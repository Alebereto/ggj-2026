extends Node3D


const ROTATE_SPEED = 3.1

const RING_WIDTH = 0.15

const THROW_COLOR: Color = Color.RED
const THROW_RADUIS: float = 0.2

const COMMAND_COLOR: Color = Color.YELLOW
const COMMAND_RADIUS: float = 0.2

const VACUUM_COLOR: Color = Color.BLUE
const VACUUM_RADIUS: float = 1.0

@onready var _ring: MeshInstance3D = $Ring
@onready var _arrow: MeshInstance3D = $Arrow
@onready var _collision: CollisionShape3D = $Area3D/CollisionShape3D
@onready var _area: Area3D = $Area3D

@onready var _vacuum_sound: AudioStreamPlayer3D = $Vacuum
@onready var _vacuum_particles: GPUParticles3D = $VacuumEffect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_mode_none()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_arrow.rotate_y(ROTATE_SPEED * delta)
	_ring.rotate_y(-ROTATE_SPEED * delta)

func _set_ring_radius(val: float) -> void:
	_ring.mesh.inner_radius = val
	_ring.mesh.outer_radius = val + RING_WIDTH
	_collision.shape.radius = val + RING_WIDTH

## =========  Public functions ================

func set_mode_none() -> void:
	vacuum_released()
	hide()


func set_mode_throw() -> void:
	vacuum_released()
	show()
	_ring.mesh.material.albedo_color = THROW_COLOR
	_set_ring_radius(THROW_RADUIS)

func set_mode_command() -> void:
	vacuum_released()
	show()
	_ring.mesh.material.albedo_color = COMMAND_COLOR
	_set_ring_radius(COMMAND_RADIUS)

func set_mode_vacuum() -> void:
	show()
	_ring.mesh.material.albedo_color = VACUUM_COLOR
	_set_ring_radius(VACUUM_RADIUS)

func vacuum_released():
	_vacuum_sound.stop()
	_vacuum_particles.emitting = false

func get_objects_in_zone() -> Array:
	if not _vacuum_sound.playing: _vacuum_sound.play()
	_vacuum_particles.emitting = true

	var res: Array = []
	for body in _area.get_overlapping_bodies():
		if body is Minion or body is Mask:
			res.append(body)
	return res
