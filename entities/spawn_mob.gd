extends Node2D

@export var mob_scene: PackedScene
@export var player: CharacterBody2D
@onready var mob_spawn_location = $Path2D/PathFollow2D

func _process(delta):
	pass

func _on_spawn_timer_timeout():
	var mob = mob_scene.instantiate()
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position
	add_child(mob)
