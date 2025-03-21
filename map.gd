extends Node2D

@export var mob_scene: PackedScene
@onready var ground_tilemap = $TileMapLayer
@export var tower_scene: PackedScene

func _process(_delta):
	pass
	
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Try to place tower at mouse position
		var mouse_pos = get_global_mouse_position()
		var tile_pos = ground_tilemap.local_to_map(mouse_pos)
		place_tower(tile_pos)

func place_tower(tile_pos: Vector2i) -> bool:
		# Instance the tower scene
		var tower = tower_scene.instantiate()
		add_child(tower)
		# Position the tower at the center of the tile
		var world_pos = ground_tilemap.map_to_local(tile_pos)
		tower.global_position = world_pos
		return true
		
func _on_spawn_timer_timeout():
	var path_follow_2d = PathFollow2D.new()
	var mob = mob_scene.instantiate()
	
	path_follow_2d.set_script(load("res://path_follow_2d.gd"))
	
	$MobPath.add_child(path_follow_2d)
	path_follow_2d.add_child(mob)
