extends Node2D

@export var mob_scene: PackedScene
@export var tower_scene: PackedScene

@onready var ground_tilemap = $GroundLayer
@onready var gold_label = $UI/GameState/Gold
@onready var health_label = $UI/GameState/Health
@onready var wave_count_label = $UI/GameState/WaveCount
@onready var enemy_count_label = $UI/GameState/EnemyCount

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
var gold: int = 50
var attack_rate: float = 1
var attack_damage: float = 10
var attack_range: float = 150
var upgrade_type = ""

var health: int = 15
@onready var menu_ui = $Menu
@onready var spawnTimer = $SpawnTimer
@onready var waveTimer = $WaveTimer
var wave_count: int = 1
var enemy_count: int = 10
var isGameStarted: bool = false
signal game_over

var mob_max_health: int = 30

func _ready():
	ability_label.text = "E-Rank Ability\n\"Rapid Fire\""
	update_ui()

func _process(delta):
	if (!isGameStarted): return
		
	if (!waveTimer.is_stopped()):
		wave_count_label.text = "Wave: %d (%d)" % [wave_count, waveTimer.time_left] 
	var mob_follow_paths = get_tree().get_nodes_in_group("mob_follow_path")
	for mob_follow_path: PathFollow2D in mob_follow_paths:
		if (mob_follow_path.progress_ratio >= 1.0):
			mob_follow_path.queue_free()
			health -= 1
			update_ui()
	if (health <= 0):
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
		add_child(tower)
		# Position the tower at the center of the tile
		var world_pos = ground_tilemap.map_to_local(tile_pos)
		tower.global_position = world_pos
		towers.append(tower)
		update_tower_stats()
		
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
		
		path_follow_2d.set_script(load("res://path_follow_2d.gd"))
		path_follow_2d.add_to_group("mob_follow_path")
		path_follow_2d.loop = false
		
		$MobPath.add_child(path_follow_2d)
		path_follow_2d.add_child(mob)

func update_ui():
	gold_label.text = "Gold: %d" % self.gold
	health_label.text = "Health: %d" % self.health
	enemy_count_label.text = "Enemey: %d" % self.enemy_count
	wave_count_label.text = "Wave: %d" % self.wave_count
	
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

func _on_game_over():
	isGameStarted = false
	get_tree().call_group("mob_follow_path", "queue_free")
	get_tree().call_group("tower", "queue_free")
	$Menu.show()
	$SpawnTimer.stop()

func start_next_wave():
	wave_count += 1  # Increase wave count
	enemy_count = wave_count * 2 + enemy_count  # Increase enemies linearly
	mob_max_health += 10

	# Scale spawn interval: Decrease spawn time slightly each wave for difficulty
	$SpawnTimer.wait_time = max($SpawnTimer.wait_time * 0.9, 1)
	$SpawnTimer.start()
	$WaveTimer.start()

	print("Wave:", wave_count, " | Enemies:", enemy_count, " | Spawn Interval:", $SpawnTimer.wait_time)

func _on_wave_timer_timeout():
	start_next_wave()
