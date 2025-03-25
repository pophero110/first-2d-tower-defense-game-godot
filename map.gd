extends Node2D

@export var mob_scene: PackedScene
@onready var ground_tilemap = $TileMapLayer
@export var tower_scene: PackedScene

@onready var gold_label = $UI/GameState/Gold
@onready var ability_label = $UI/Ability
@onready var attack_rate_label = $UI/AttackRate
@onready var attack_damage_label = $UI/AttackDamage

var towers = []
var gold: int = 50
var attack_rate: float = 1
var attack_damage: float = 10
var ability_cooldown_in_seconds: float = 10

func _ready():
	update_ui()

func _on_mob_died():
	gold += 10
	update_ui() 
	
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Try to place tower at mouse position
		var mouse_pos = get_global_mouse_position()
		var tile_pos = ground_tilemap.local_to_map(mouse_pos)
		
		var clicked_cell = ground_tilemap.local_to_map(ground_tilemap.get_local_mouse_position())
		var tileData = ground_tilemap.get_cell_tile_data(clicked_cell)
		if (!is_tower_at_position(tile_pos) && tileData.get_custom_data("placable") && gold >= 50):
			place_tower(tile_pos)
			gold -= 50
			update_ui()

func is_tower_at_position(tile_pos: Vector2i) -> bool:
	var world_pos = ground_tilemap.map_to_local(tile_pos);
	for tower in towers:
		if tower.global_position == world_pos:
			return true  # Tower already exists here
	return false  # No tower at this position
	
func place_tower(tile_pos: Vector2i):
		var tower = tower_scene.instantiate()
		add_child(tower)
		# Position the tower at the center of the tile
		var world_pos = ground_tilemap.map_to_local(tile_pos)
		tower.global_position = world_pos
		towers.append(tower)
		update_tower_stats()
		
func _on_spawn_timer_timeout():
	var path_follow_2d = PathFollow2D.new()
	var mob = mob_scene.instantiate()
	
	mob.died.connect(_on_mob_died)
	
	path_follow_2d.set_script(load("res://path_follow_2d.gd"))
	
	$MobPath.add_child(path_follow_2d)
	path_follow_2d.add_child(mob)

func update_ui():
	gold_label.text = "Gold: %d" % gold
	ability_label.text = "E-Rank Ability: Rapid Fire"
	attack_rate_label.text = "Attack Rate: %.2f" % attack_rate
	attack_damage_label.text = "Attack Damage: %.2f" % attack_damage

func update_tower_stats():
	for tower in towers:
		tower.attack_rate = self.attack_rate
		tower.attack_damage = self.attack_damage
		tower.ability_cooldown_in_seconds = self.ability_cooldown_in_seconds

func _on_inc_atk_dmg_pressed():
	if (gold >= 50):
		attack_damage *= 1.10
		gold -= 50
		update_ui()
		update_tower_stats()

func _on_dec_ability_cd_pressed():
	if (gold >= 50):
		gold -= 50
		ability_cooldown_in_seconds *= 0.9
		update_ui()
		update_tower_stats()


func _on_dec_atk_rate_pressed():
	if (gold >= 50):
		gold -= 50
		attack_rate *= 0.9
		update_ui()
		update_tower_stats()
