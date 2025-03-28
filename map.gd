extends Node2D

@export var mob_scene: PackedScene
@export var tower_scene: PackedScene

@onready var ground_tilemap = $GroundLayer
@onready var gold_label = $UI/GameState/Gold
@onready var health_label = $UI/GameState/Health
@onready var wave_count_label = $UI/GameState/WaveCount
@onready var enemy_count_label = $UI/GameState/EnemyCount

@onready var ability_label = $UI/Ability
@onready var ability_shout_out_label = $UI/AbilityShoutOut
@onready var attack_rate_label = $UI/AttackRate
@onready var attack_damage_label = $UI/AttackDamage
@onready var attack_range_label = $UI/AttackRange
@onready var inc_attack_speed_button = $UI/IncAtkSpeed
@onready var inc_attack_damage_button = $UI/IncAtkDmg
@onready var inc_attack_range_button = $UI/IncAtkRange
@onready var upgrade_confirm_dialog = $UI/UpgradeConfirmDialog
@onready var error_dialog = $UI/ErrorDialog  # Reference the error popup

var towers = []
var gold: int = 50
var attack_rate: float = 1
var attack_damage: float = 10
var attack_range: float = 150
var tower_ability = null
var upgrade_type = ""

var player_health: int = 15
@onready var menu_ui = $Menu
@onready var spawnTimer = $SpawnTimer
@onready var waveTimer = $WaveTimer
var wave_count: int = 1
var enemy_count: int = 10
var isGameStarted: bool = false
signal game_over

var mob_max_health: int = 10000

func _ready():
	update_ui()

func _process(_delta):
	if (!isGameStarted): return
		
	if (!waveTimer.is_stopped()):
		wave_count_label.text = "Wave: %d (%d)" % [wave_count, waveTimer.time_left] 
	var mob_path_follows = get_tree().get_nodes_in_group("mob_path_follow")
	for mob_path_follow: PathFollow2D in mob_path_follows:
		if (mob_path_follow.progress_ratio >= 1.0):
			mob_path_follow.queue_free()
			player_health -= 1
			update_ui()
	if (player_health <= 0):
		game_over.emit()

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
		var copied_tower_ability = tower_ability.duplicate()
		tower.ability = copied_tower_ability
		add_child(tower)
		tower.add_child(copied_tower_ability)
		# Position the tower at the center of the tile
		var world_pos = ground_tilemap.map_to_local(tile_pos)
		tower.global_position = world_pos
		towers.append(tower)
		update_tower_stats()
		
func get_random_ability():
	var abilities = [
		{"scene_name": "rapid_fire", "rank": 1},
		{"scene_name": "dual_fire", "rank": 1},
		{"scene_name": "explosive_missle", "rank": 30}
	]

	# Create a weighted list based on rank
	var weighted_list = []
	for ability in abilities:
		for i in range(ability["rank"]):  
			weighted_list.append(ability["scene_name"])

	# Randomly select from the weighted list
	var selected_ability = weighted_list[randi() % weighted_list.size()]
	var ability_scene_node = preload("res://entities/abilities/ability.tscn").instantiate()
	ability_scene_node.set_script(load("res://entities/abilities/%s.gd" % selected_ability))
	return ability_scene_node
		
func _on_spawn_timer_timeout():
	if (enemy_count == 0):
		$WaveTimer.start()
		$SpawnTimer.stop()
	else:
		enemy_count -= 1
		update_ui()
		var path_follow_2d = PathFollow2D.new()
		var mob = mob_scene.instantiate()
		mob.health = mob_max_health
		mob.max_health = mob_max_health
		
		mob.died.connect(_on_mob_died)
		
		path_follow_2d.set_script(load("res://entities/mob_path_follow.gd"))
		path_follow_2d.add_to_group("mob_path_follow")
		path_follow_2d.loop = false
		
		$MobPath.add_child(path_follow_2d)
		path_follow_2d.add_child(mob)

func update_ui():
	gold_label.text = "Gold: %d" % self.gold
	health_label.text = "Health: %d" % self.player_health
	enemy_count_label.text = "Enemey: %d" % self.enemy_count
	wave_count_label.text = "Wave: %d" % self.wave_count
	
	attack_rate_label.text = "Attack Rate: %.2f" % self.attack_rate
	attack_damage_label.text = "Attack Damage: %.2f" % self.attack_damage
	attack_range_label.text = "Attack Range: %.2f" % self.attack_range

	var atk_dmg_cost = calculate_cost(attack_damage, 50, 1.15)
	var atk_rate_cost = calculate_cost(attack_rate, 50, 1.15)
	var atk_range_cost = calculate_cost(attack_range, 50, 1.01)
	# Update button colors based on gold availability
	inc_attack_damage_button.text = "Upgrade($%s)" % atk_dmg_cost
	inc_attack_speed_button.text = "Upgrade($%s)" % atk_rate_cost
	inc_attack_range_button.text = "Upgrade($%s)" % atk_range_cost
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
		upgrade_confirm_dialog.dialog_text = "Increase Attack Damage by 10% for %d Gold?" % [cost]
		upgrade_confirm_dialog.popup_centered()
	else:
		show_error("Not enough gold!")

func _on_dec_atk_rate_pressed():
	var cost = calculate_cost(attack_rate, 50, 1.15)
	if gold >= cost:
		upgrade_type = "attack_rate"
		upgrade_confirm_dialog.dialog_text = "Increase Attack Speed by 10%% for %d Gold?" % [cost]
		upgrade_confirm_dialog.popup_centered()
	else:
		show_error("Not enough gold!")

func _on_inc_atk_range_pressed():
	var cost = calculate_cost(attack_range, 50, 1.01)
	if gold >= cost:
		upgrade_type = "attack_range"
		upgrade_confirm_dialog.dialog_text = "Increase Attack Range by 10%% for %d Gold?" % [cost]
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

func _on_start_game_pressed():
	isGameStarted = true
	$Menu.hide()
	$SpawnTimer.start()
	$WaveTimer.start()
	tower_ability = get_random_ability()
	ability_shout_out_label.text = "%s-Rank Ability\n%s" % [tower_ability.rank, tower_ability.display_name]
	$UI/GameStartAnimation.play("ability_shout_out")
	
func _on_game_over():
	isGameStarted = false
	get_tree().call_group("mob_path_follow", "queue_free")
	get_tree().call_group("tower", "queue_free")
	towers = []
	wave_count = 1
	enemy_count = 10
	gold = 50
	player_health = 15
	$Menu.show()
	$SpawnTimer.stop()
	$WaveTimer.stop()

func start_next_wave():
	wave_count += 1  # Increase wave count
	enemy_count = wave_count * 2 + 10  # Increase enemies linearly
	mob_max_health += 10

	# Scale spawn interval: Decrease spawn time slightly each wave for difficulty
	$SpawnTimer.wait_time = max($SpawnTimer.wait_time * 0.9, 0.1)
	$SpawnTimer.start()
	$WaveTimer.start()

	print("Wave:", wave_count, " | Enemies:", enemy_count, " | Spawn Interval:", $SpawnTimer.wait_time)

func _on_wave_timer_timeout():
	start_next_wave()

func _on_game_start_animation_animation_finished():
	ability_label.text = "%s-Rank Ability\n%s" % [tower_ability.rank, tower_ability.display_name]
