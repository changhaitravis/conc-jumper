class_name ConcGrenade
extends RigidBody3D

@export var fuse_time: float = 4.0
@export var blast_radius: float = 12.0
@export var blast_force: float = 38.0
@export var upward_bias: float = 0.55

var time_remaining: float
var is_held: bool = true
var player_ref: Player = null

@onready var timer_label: Label3D = $TimerLabel

func _ready() -> void:
	freeze = true

func init_primed(player: Player) -> void:
	player_ref = player
	time_remaining = fuse_time
	is_held = true
	freeze = true
	top_level = true

func _physics_process(delta: float) -> void:
	time_remaining -= delta
	if timer_label:
		timer_label.text = "%.1f" % max(time_remaining, 0.0)

	if is_held and player_ref:
		global_position = player_ref.projectile_spawn.global_position

	if time_remaining <= 0.0:
		detonate()

func throw_grenade(direction: Vector3, throw_speed: float) -> void:
	is_held = false
	freeze = false
	linear_velocity = (direction * throw_speed) + (player_ref.velocity * 0.5)

func detonate() -> void:
	if player_ref and is_instance_valid(player_ref):
		player_ref.apply_explosion_impulse(global_position, blast_force, blast_radius, upward_bias)
	
	queue_free()
