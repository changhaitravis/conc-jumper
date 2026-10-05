class_name Rocket
extends CharacterBody3D

@export var speed: float = 40.0
@export var blast_radius: float = 7.0
@export var blast_force: float = 24.0
@export var upward_bias: float = 0.45

var direction: Vector3 = Vector3.FORWARD
var shooter: Player = null

func launch(launch_dir: Vector3, player: Player) -> void:
	direction = launch_dir.normalized()
	shooter = player

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(direction * speed * delta)
	if collision:
		detonate(collision.get_position())

func detonate(impact_pos: Vector3) -> void:
	if shooter and is_instance_valid(shooter):
		shooter.apply_explosion_impulse(impact_pos, blast_force, blast_radius, upward_bias)
	
	queue_free()
