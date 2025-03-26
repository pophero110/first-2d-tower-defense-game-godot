extends Node2D

@export var mob_scene: PackedScene
@export var tower_scene: PackedScene

@onready var ground_tilemap = $TileMapLayer
@onready var gold_label = $UI/GameState/Gold
@onready var ability_label = $UI/Ability
@onready var attack_rate_label = $UI/AttackRate
@onready var attack_damage_label = $UI/AttackDamage
@onready var attack_range_label = $UI/AttackRange
@onready var inc_attack_speed_button = $UI/IncAtkSpeed
@onready var inc_attack_damage_button = $UI/IncAtkDmg
@onready var inc_attack_range_button = $UI/IncAtkRange
@onready var upgrade_confirm_dialog = $UI/UpgradeConfirmDialog
@onready var error_dialog = $UI/ErrorDialog  # Reference the error popup

var towers = []
var gold: int = 5000
var attack_rate: float = 1
var attack_damage: float = 10
var attack_range: float = 150
var upgrade_type = ""

var waveCount: int = 1
var enemyTotalCount: int = 10
var enemyCount: int = 10
@onready var spawnTimer = $SpawnTimer

func _ready():
	ability_label.text = "E-Rank Ability\n\"Rapid Fire\""
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
		if (tileData == null): return
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
	mob.health = 30
	mob.max_health = 30
	
	mob.died.connect(_on_mob_died)
	
	path_follow_2d.set_script(load("res://path_follow_2d.gd"))
	
	$MobPath.add_child(path_follow_2d)
	path_follow_2d.add_child(mob)

func update_ui():
	gold_label.text = "Gold: %d" % self.gold
	attack_rate_label.text = "Attack Rate: %.2f" % self.attack_rate
	attack_damage_label.text = "Attack Damage: %.2f" % self.attack_damage
	attack_range_label.text = "Attack Range: %.2f" % self.attack_range

	var atk_dmg_cost = calculate_cost(attack_damage, 50, 1.15)
	var atk_rate_cost = calculate_cost(attack_rate, 50, 1.15)
	var atk_range_cost = calculate_cost(attack_range, 50, 1.01)
	# Update button colors based on gold availability
	update_button_style(inc_attack_speed_button, gold >= atk_rate_cost)
	update_button_style(inc_attack_damage_button, gold >= atk_dmg_cost)
	update_button_style(inc_attack_range_button, gold >= atk_range_cost)

func update_button_style(button: Button, can_afford: bool):
	var style: StyleBoxFlat = button.get_theme_stylebox("normal").duplicate()
	style.bg_color = Color(0.5, 0.7, 1) if can_afford else Color(0.3, 0.3, 0.3)  # Light blue if affordable, gray otherwise
	button.add_theme_stylebox_override("normal", style)

func update_tower_stats():
	for tower in towers:
		tower.attack_rate = self.attack_rate
		tower.attack_damage = self.attack_damage
		tower.attack_range = self.attack_range
		tower.queue_redraw()

func _on_inc_atk_dmg_pressed():
	var cost = calculate_cost(attack_damage, 50, 1.15)
	if gold >= cost:
		upgrade_type = "attack_damage"
		upgrade_confirm_dialog.dialog_text = "Upgrade Attack Damage by 10% for %d Gold?" % [cost]
		upgrade_confirm_dialog.popup_centered()
	else:
		show_error("Not enough gold!")

func _on_dec_atk_rate_pressed():
	var cost = calculate_cost(attack_rate, 50, 1.15)
	if gold >= cost:
		upgrade_type = "attack_rate"
		upgrade_confirm_dialog.dialog_text = "Upgrade Attack Rate by 10%% for %d Gold?" % [cost]
		upgrade_confirm_dialog.popup_centered()
	else:
		show_error("Not enough gold!")

func _on_inc_atk_range_pressed():
	var cost = calculate_cost(attack_range, 50, 1.01)
	if gold >= cost:
		upgrade_type = "attack_range"
		upgrade_confirm_dialog.dialog_text = "Upgrade Attack Range by 10%% for %d Gold?" % [cost]
		upgrade_confirm_dialog.popup_centered()
	else:
		show_error("Not enough gold!")

func _on_upgrade_confirm_dialog_confirmed():
	var cost = 0
	if upgrade_type == "attack_damage":
		cost = calculate_cost(attack_damage, 50, 1.15)
		if gold >= cost:
			gold -= cost
			attack_damage *= 1.10
		else:
			show_error("Not enough gold!")
	elif upgrade_type == "attack_rate":
		cost = calculate_cost(attack_rate, 50, 1.15)
		if gold >= cost:
			gold -= cost
			attack_rate *= 0.9
		else:
			show_error("Not enough gold!")
	elif upgrade_type == "attack_range":
		cost = calculate_cost(attack_range, 50, 1.01)
		if gold >= cost:
			gold -= cost
			attack_range *= 1.10
		else:
			show_error("Not enough gold!")

	update_ui()
	update_tower_stats()
	
func show_error(message: String):
	error_dialog.dialog_text = message
	error_dialog.popup_centered()

# Scaling cost function based on current value
func calculate_cost(stat_value: float, base_cost: int, growth_factor: float) -> int:
	return int(base_cost * pow(growth_factor, stat_value))
