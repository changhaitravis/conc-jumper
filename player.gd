class_name Player
extends CharacterBody3D

@export_group("Movement Constants")
@export var max_ground_speed: float = 12.0
@export var ground_accel: float = 14.0
@export var ground_friction: float = 6.0
@export var air_max_speed: float = 2.5
@export var air_accel: float = 50.0
@export var jump_impulse: float = 9.0
@export var gravity: float = 24.0

@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var max_pitch: float = 89.0

@export_group("Weapons & Abilities")
@export var conc_scene: PackedScene
@export var rocket_scene: PackedScene
@export var max_concs: int = 4

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_holder: Node3D = $Head/Camera3D/WeaponHolder
@onready var projectile_spawn: Marker3D = $Head/Camera3D/WeaponHolder/ProjectileSpawn

var is_crouching: bool = false
var conc_inventory: int = 4
var active_primed_conc: RigidBody3D = null
var spawn_checkpoint_transform: Transform3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawn_checkpoint_transform = global_transform
	conc_inventory = max_concs

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))

	if event.is_action_pressed("prime_conc"):
		start_prime_conc()
	elif event.is_action_released("prime_conc"):
		release_conc()

	if event.is_action_pressed("fire_rocket"):
		fire_rocket()

	if event.is_action_pressed("restart_checkpoint"):
		respawn_at_checkpoint()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var wish_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		_handle_ground_physics(delta, wish_dir)
		if Input.is_action_pressed("jump"):
			velocity.y = jump_impulse
	else:
		_handle_air_physics(delta, wish_dir)

	move_and_slide()

func _handle_ground_physics(delta: float, wish_dir: Vector3) -> void:
	var speed := velocity.length()
	if speed != 0.0:
		var drop := speed * ground_friction * delta
		velocity *= max(speed - drop, 0.0) / speed

	var cur_speed := velocity.dot(wish_dir)
	var add_speed := max_ground_speed - cur_speed
	if add_speed > 0.0:
		var accel_speed := ground_accel * max_ground_speed * delta
		accel_speed = min(accel_speed, add_speed)
		velocity += wish_dir * accel_speed

func _handle_air_physics(delta: float, wish_dir: Vector3) -> void:
	velocity.y -= gravity * delta

	if wish_dir != Vector3.ZERO:
		var cur_speed := velocity.dot(wish_dir)
		var add_speed := air_max_speed - cur_speed
		if add_speed > 0.0:
			var accel_speed := air_accel * air_max_speed * delta
			accel_speed = min(accel_speed, add_speed)
			velocity += wish_dir * accel_speed

func apply_explosion_impulse(explosion_pos: Vector3, max_force: float, radius: float, upward_bias: float = 0.6) -> void:
	var player_center := global_position + Vector3(0, 0.9, 0)
	var delta_pos := player_center - explosion_pos
	var distance := delta_pos.length()

	if distance > radius:
		return

	var dir := delta_pos.normalized()
	dir.y += upward_bias
	dir = dir.normalized()

	var falloff := 1.0 - clamp(distance / radius, 0.0, 1.0)
	var final_impulse := dir * max_force * falloff

	velocity += final_impulse

func start_prime_conc() -> void:
	if conc_inventory <= 0 or active_primed_conc != null:
		return
	conc_inventory -= 1
	var conc = conc_scene.instantiate()
	get_tree().root.add_child(conc)
	conc.init_primed(self)
	active_primed_conc = conc

func release_conc() -> void:
	if active_primed_conc != null and is_instance_valid(active_primed_conc):
		var throw_direction := -camera.global_transform.basis.z
		active_primed_conc.throw_grenade(throw_direction, 22.0)
		active_primed_conc = null

func fire_rocket() -> void:
	if rocket_scene == null:
		return
	var rocket = rocket_scene.instantiate()
	get_tree().root.add_child(rocket)
	rocket.global_transform = projectile_spawn.global_transform
	rocket.launch(-camera.global_transform.basis.z, self)

func respawn_at_checkpoint() -> void:
	global_transform = spawn_checkpoint_transform
	velocity = Vector3.ZERO
	conc_inventory = max_concs
