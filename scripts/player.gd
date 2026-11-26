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
@export var crouch_speed_multiplier: float = 0.45

@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var max_pitch: float = 89.0

@export_group("Weapons & Abilities")
@export var conc_scene: PackedScene
@export var rocket_scene: PackedScene
@export var max_concs: int = 4
@export var conc_throw_speed: float = 22.0

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.1
const HEAD_STAND_HEIGHT := 1.5
const HEAD_CROUCH_HEIGHT := 0.9

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
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
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			release_conc()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# Click to re-capture the mouse instead of firing while uncaptured.
		if event.is_action_pressed("fire_rocket"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion:
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

	var wants_crouch := Input.is_action_pressed("crouch")
	if wants_crouch:
		is_crouching = true
	elif is_crouching and not test_move(global_transform, Vector3(0, STAND_HEIGHT - CROUCH_HEIGHT, 0)):
		is_crouching = false
	_apply_crouch_dimensions()

	var max_speed := max_ground_speed * (crouch_speed_multiplier if is_crouching else 1.0)

	if is_on_floor():
		if Input.is_action_pressed("jump"):
			velocity.y = jump_impulse
			_accelerate(delta, wish_dir, air_max_speed, air_accel)
		else:
			_handle_ground_physics(delta, wish_dir, max_speed)
	else:
		velocity.y -= gravity * delta
		_accelerate(delta, wish_dir, air_max_speed, air_accel)

	move_and_slide()

func _apply_crouch_dimensions() -> void:
	head.position.y = HEAD_CROUCH_HEIGHT if is_crouching else HEAD_STAND_HEIGHT
	var target_height := CROUCH_HEIGHT if is_crouching else STAND_HEIGHT
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule and not is_equal_approx(capsule.height, target_height):
		capsule.height = target_height
		collision_shape.position.y = target_height * 0.5

func _handle_ground_physics(delta: float, wish_dir: Vector3, max_speed: float) -> void:
	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	var speed := horiz.length()
	if speed > 0.0:
		var drop := speed * ground_friction * delta
		var scale := maxf(speed - drop, 0.0) / speed
		velocity.x *= scale
		velocity.z *= scale

	_accelerate(delta, wish_dir, max_speed, ground_accel)

func _accelerate(delta: float, wish_dir: Vector3, max_speed: float, accel: float) -> void:
	if wish_dir == Vector3.ZERO:
		return
	var cur_speed := velocity.dot(wish_dir)
	var add_speed := max_speed - cur_speed
	if add_speed > 0.0:
		var accel_speed := minf(accel * max_speed * delta, add_speed)
		velocity += wish_dir * accel_speed

func apply_explosion_impulse(explosion_pos: Vector3, max_force: float, radius: float, upward_bias: float = 0.6) -> void:
	var player_center := global_position + Vector3(0, 0.9, 0)
	var delta_pos := player_center - explosion_pos
	var distance := delta_pos.length()

	if distance > radius:
		return

	var dir := Vector3.UP if distance < 0.001 else delta_pos.normalized()
	dir.y += upward_bias
	dir = dir.normalized()

	var falloff: float = 1.0 - clampf(distance / radius, 0.0, 1.0)
	var final_impulse: Vector3 = dir * max_force * falloff

	velocity += final_impulse

func start_prime_conc() -> void:
	if conc_scene == null:
		return
	if conc_inventory <= 0 or active_primed_conc != null:
		return
	conc_inventory -= 1
	var conc = conc_scene.instantiate()
	get_tree().root.add_child(conc)
	conc.init_primed(self)
	active_primed_conc = conc

func clear_primed_conc(conc: Node = null) -> void:
	if conc == null or active_primed_conc == conc:
		active_primed_conc = null

func release_conc() -> void:
	if active_primed_conc != null and is_instance_valid(active_primed_conc):
		var throw_direction := -camera.global_transform.basis.z
		active_primed_conc.throw_grenade(throw_direction, conc_throw_speed)
		active_primed_conc = null

func fire_rocket() -> void:
	if rocket_scene == null:
		return
	var rocket = rocket_scene.instantiate()
	get_tree().root.add_child(rocket)
	var spawn_pos := projectile_spawn.global_position
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		camera.global_position,
		spawn_pos,
		1,
		[get_rid()]
	)
	var hit := space_state.intersect_ray(query)
	if not hit.is_empty():
		spawn_pos = hit.position - (spawn_pos - camera.global_position).normalized() * 0.25
	rocket.global_transform = projectile_spawn.global_transform
	rocket.global_position = spawn_pos
	rocket.launch(-camera.global_transform.basis.z, self)

func respawn_at_checkpoint() -> void:
	if active_primed_conc != null and is_instance_valid(active_primed_conc):
		active_primed_conc.queue_free()
	active_primed_conc = null
	global_transform = spawn_checkpoint_transform
	velocity = Vector3.ZERO
	conc_inventory = max_concs
	is_crouching = false
	_apply_crouch_dimensions()
