extends Node2D

@export var mob_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_spawn_timer_timeout():
	var path_follow_2d = PathFollow2D.new()
	var mob = mob_scene.instantiate()
	
	path_follow_2d.set_script(load("res://path_follow_2d.gd"))
	
	$MobPath.add_child(path_follow_2d)
	path_follow_2d.add_child(mob)
