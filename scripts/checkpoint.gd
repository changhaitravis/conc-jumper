class_name Checkpoint
extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.spawn_checkpoint_transform = global_transform
		body.conc_inventory = body.max_concs
