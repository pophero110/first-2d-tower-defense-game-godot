extends Node2D

# === Nodes ===
@export var tower_scene: PackedScene
@export var wall_scene: PackedScene
@export var mob_scene: PackedScene

# === Player ===
@onready var player = $Player
@onready var collect_bar = $Player/CollectBar
@onready var day_night_countdown_label = $Player/HUD/DayNightCountdown
@onready var wood_resource_label = $Player/HUD/WoodResource
@onready var stone_resource_label = $Player/HUD/StoneResource
@onready var collect_timer = $Player/CollectTimer
@onready var collect_indicator = $CollectIndicator

# === Game ===
@onready var building_layer = $BuildingLayer
@onready var day_night_timer = $DayNightTimer
@onready var ground_tilemaplayer: TileMapLayer = $GroundTileMapLayer
@onready var resource_tilemaplayer = $ResourceTileMapLayer
@onready var mob_spawn_location = $MobPath/MobSpawnLocation
@onready var navigation_region = $NavigationRegion2D

# === Settings ===
var collect_distance = 120.0
var collect_time = 2.0
var highlight_color_green = Color(0, 1, 0, 0.4)
var highlight_color_red = Color(1, 0, 0, 0.4)

# === State ===
var is_collecting = false
var current_target_cell = null
var player_collect_start_pos = Vector2.ZERO
var current_resource_type = ""
var buildings = []
var isNight = false
var selected_building = null
var build_mode = false
var buildable = false

enum Building {
	TOWER,
	WALL
}
# === Resource ===
var wood_resource = 5000
var stone_resource = 0

# === Lifecycle ===
func _ready():
	collect_indicator.visible = false
	collect_timer.wait_time = collect_time
	collect_bar.visible = false
	collect_bar.min_value = 0
	collect_bar.max_value = collect_time
	collect_bar.value = 0
	
	building_layer.placed_building.connect(_on_placed_building)

func _process(delta):
	if !day_night_timer.is_stopped():
		if isNight:
			day_night_countdown_label.text = "Night: %d" % day_night_timer.time_left
		else:
			day_night_countdown_label.text = "Day: %d" % day_night_timer.time_left
	if is_collecting:
		collect_bar.value = collect_time - collect_timer.time_left
		if player.global_position != player_collect_start_pos:
			cancel_collection()

# === Building System ===
func _on_placed_building(building):
	navigation_region.add_child(building)
	navigation_region.bake_navigation_polygon()
	building.died.connect(_on_building_died)
	building_layer.build_mode = false
	
func _on_building_died(building):
	await get_tree().process_frame
	buildings.erase(building)
	navigation_region.bake_navigation_polygon()
	
func _on_tower_pressed():
	build_mode = true
	building_layer.build_mode = true
	building_layer.selected_building_scene = load("res://entities/tower.tscn")

func _on_wall_pressed():
	build_mode = true
	building_layer.build_mode = true
	building_layer.selected_building_scene = load("res://entities/wall.tscn")

# === Collection Control ===
func start_collection(cell):
	is_collecting = true
	current_target_cell = cell
	player_collect_start_pos = player.global_position

	collect_bar.value = 0
	collect_bar.visible = true
	collect_timer.start()

func cancel_collection():
	is_collecting = false
	current_target_cell = null
	collect_timer.stop()

	collect_bar.visible = false
	collect_bar.value = 0
	collect_indicator.visible = false

	print("Collection cancelled due to movement.")

func _on_collect_timer_timeout():
	is_collecting = false
	collect_bar.visible = false
	collect_bar.value = 0

	if current_target_cell:
		resource_tilemaplayer.erase_cell(current_target_cell)
		current_target_cell = null

		if current_resource_type == "wood":
			wood_resource += 10
			wood_resource_label.text = "Wood: %d" % wood_resource
		elif current_resource_type == "stone":
			stone_resource += 10
			stone_resource_label.text = "Stone: %d" % stone_resource
		current_resource_type = ""
	collect_indicator.visible = false
	
#=== Mob Spawn ===
func _on_mob_timer_timeout():
	#if isNight:
		var mob = mob_scene.instantiate()
		mob.player = player
		mob_spawn_location.progress_ratio = randf()
		mob.position = mob_spawn_location.position
		navigation_region.add_child(mob)

func _on_day_night_timer_timeout():
	isNight = !isNight
