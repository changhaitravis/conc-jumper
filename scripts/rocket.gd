class_name Rocket
extends CharacterBody3D

@export var speed: float = 40.0
@export var blast_radius: float = 7.0
@export var blast_force: float = 24.0
@export var upward_bias: float = 0.45
@export var lifetime: float = 5.0

var direction: Vector3 = Vector3.FORWARD
var shooter: Player = null
var _age: float = 0.0

func launch(launch_dir: Vector3, player: Player) -> void:
	direction = launch_dir.normalized()
	shooter = player
	if player:
		add_collision_exception_with_body(player)

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		# Fizzle out instead of living forever on a missed shot.
		queue_free()
		return
	var collision := move_and_collide(direction * speed * delta)
	if collision:
		detonate(collision.get_position())

func detonate(impact_pos: Vector3) -> void:
	if shooter and is_instance_valid(shooter):
		shooter.apply_explosion_impulse(impact_pos, blast_force, blast_radius, upward_bias)

	queue_free()
