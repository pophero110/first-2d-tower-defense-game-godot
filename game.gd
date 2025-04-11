extends Node2D

# === Nodes ===
@onready var tree_tilemap = $Tree
@onready var player = $Player
@onready var collect_timer = $CollectTimer
@onready var collect_bar = $Player/CollectBar
@onready var tile_highlight = $TileHighlight
@onready var collect_indicator = $CollectIndicator

# === Settings ===
var collect_distance = 120.0
var collect_time = 2.0
var highlight_color_near = Color(0, 1, 0, 0.4)
var highlight_color_far = Color(1, 0, 0, 0.4)

# === State ===
var is_collecting = false
var current_target_cell = null
var player_collect_start_pos = Vector2.ZERO

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
	if is_collecting:
		collect_bar.value = collect_time - collect_timer.time_left
		if player.global_position != player_collect_start_pos:
			cancel_collection()

# === Input ===
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_collecting:
			return

		var mouse_pos = tree_tilemap.get_local_mouse_position()
		var cell = tree_tilemap.local_to_map(mouse_pos)
		var tile_data = tree_tilemap.get_cell_tile_data(cell)

		if tile_data:
			var tile_pos = tree_tilemap.map_to_local(cell)
			var world_pos = tree_tilemap.to_global(tile_pos)
			var distance = player.global_position.distance_to(world_pos)

			tile_highlight.global_position = world_pos - tile_highlight.size / 2
			tile_highlight.visible = true

			if distance <= collect_distance:
				tile_highlight.color = highlight_color_near
				collect_indicator.global_position = tile_highlight.global_position
				collect_indicator.visible = true
				start_collection(cell)
			else:
				tile_highlight.color = highlight_color_far
				collect_indicator.visible = false

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
		tree_tilemap.erase_cell(current_target_cell)
		current_target_cell = null

	tile_highlight.visible = false
	collect_indicator.visible = false

	print("Collection complete!")
