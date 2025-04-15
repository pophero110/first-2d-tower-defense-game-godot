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
@onready var day_night_timer = $DayNightTimer
@onready var ground_tilemaplayer = $GroundTileMapLayer
@onready var resource_tilemaplayer = $ResourceTileMapLayer
@onready var tile_highlight = $TileHighlight
@onready var build_preview: Sprite2D = $BuildingPreview
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
	tile_highlight.visible = false
	collect_indicator.visible = false

	collect_timer.wait_time = collect_time
	collect_bar.visible = false
	collect_bar.min_value = 0
	collect_bar.max_value = collect_time
	collect_bar.value = 0

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
	if build_mode:
		var mouse_pos = ground_tilemaplayer.get_local_mouse_position()
		var ground_cell = ground_tilemaplayer.local_to_map(mouse_pos)
		var ground_tile_data = ground_tilemaplayer.get_cell_tile_data(ground_cell)
		var ground_tile_pos = resource_tilemaplayer.map_to_local(ground_cell)
		var ground_tile_world_pos = resource_tilemaplayer.to_global(ground_tile_pos)
		
		var resource_cell = resource_tilemaplayer.local_to_map(mouse_pos)
		var resource_tile_data = resource_tilemaplayer.get_cell_tile_data(resource_cell)
		if ground_tile_data:
			tile_highlight.global_position = ground_tile_world_pos - tile_highlight.size / 2
			tile_highlight.visible = true
			build_preview.global_position = ground_tile_world_pos
			build_preview.visible = true
			if selected_building == Building.TOWER:
				build_preview.scale = Vector2(1,1)
				build_preview.texture = load("res://assets/towers/cannon/tier1/gun_idle_00.png")
			elif selected_building == Building.WALL:
				build_preview.scale = Vector2(0.333,0.333)
				build_preview.texture = load("res://assets/objective/objective_idle_00.png")
			if resource_tile_data == null and ground_tile_data.get_custom_data("placable"):
				tile_highlight.color = highlight_color_green
				buildable = true
			else:
				tile_highlight.color = highlight_color_red
				buildable = false

# === Input ===
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = resource_tilemaplayer.get_local_mouse_position()
		var resource_cell = resource_tilemaplayer.local_to_map(mouse_pos)
		var resource_tile_data = resource_tilemaplayer.get_cell_tile_data(resource_cell)

		var ground_cell = ground_tilemaplayer.local_to_map(mouse_pos)
		var ground_tile_data = ground_tilemaplayer.get_cell_tile_data(ground_cell)
		
		if !build_mode and resource_tile_data and !is_collecting:
			var resource_tile_pos = resource_tilemaplayer.map_to_local(resource_cell)
			var resource_tile_world_pos = resource_tilemaplayer.to_global(resource_tile_pos)

			tile_highlight.global_position = resource_tile_world_pos - tile_highlight.size / 2
			tile_highlight.visible = true
			collect_indicator.global_position = resource_tile_world_pos - tile_highlight.size / 2
			collect_indicator.visible = true
			
			current_resource_type = resource_tile_data.get_custom_data("type")

			var resource_distance = player.global_position.distance_to(resource_tile_pos)
			if resource_distance <= collect_distance:
				tile_highlight.color = highlight_color_green
				start_collection(resource_cell)
			else:
				tile_highlight.color = highlight_color_red
		elif buildable and build_mode and ground_tile_data and ground_tile_data.get_custom_data("placable"):
			if (is_building_at_position(ground_cell)): 
				print("Build: position occupied", ground_cell)
				return
			if selected_building == Building.TOWER:
				if (wood_resource >= 50):
					var tower = tower_scene.instantiate()
					place_building(ground_cell, tower)
					wood_resource -= 50
					wood_resource_label.text = "Wood: %d" % wood_resource
			elif selected_building == Building.WALL:
				if (wood_resource >= 50):
					var wall = wall_scene.instantiate()
					place_building(ground_cell, wall)
					wood_resource -= 50
					wood_resource_label.text = "Wood: %d" % wood_resource

func is_building_at_position(tile_pos: Vector2i) -> bool:
	var world_pos = ground_tilemaplayer.map_to_local(tile_pos);
	for building in buildings:
		if building.global_position == world_pos:
			return true  # Tower already exists here
	return false  # No tower at this position
	
func place_building(tile_pos: Vector2i, building):
	navigation_region.add_child(building)
	# Position the tower at the center of the tile
	var world_pos = ground_tilemaplayer.map_to_local(tile_pos)
	building.global_position = world_pos
	building.died.connect(_on_building_died)
	buildings.append(building)
	navigation_region.bake_navigation_polygon()
	tile_highlight.visible = false
	build_preview.visible = false
	build_mode = false

func _on_building_died(building):
	await get_tree().process_frame
	buildings.erase(building)
	navigation_region.bake_navigation_polygon()
	
func _on_tower_pressed():
	selected_building = Building.TOWER
	build_mode = true

func _on_wall_pressed():
	selected_building = Building.WALL
	build_mode = true

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
	tile_highlight.visible = false
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

	tile_highlight.visible = false
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
