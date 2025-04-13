extends Node2D

@export var mob_scene: PackedScene
@onready var player = $Player
@onready var nav_region = $NavigationRegion2D
@onready var mob_spawn_location = $Path2D/PathFollow2D

func _ready():
	player.died.connect(_on_player_die)

func _process(delta):
	pass

func _on_spawn_timer_timeout():
	var mob = mob_scene.instantiate()
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position
	nav_region.add_child(mob)
	
func _on_player_die():
	print("player died")
