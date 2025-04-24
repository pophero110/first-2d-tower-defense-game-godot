extends Node2D

@onready var tile_highlight = $TileHighlight;
@export var selected_building_scene = null
@export var build_mode: bool = false

var selected_building = null
var highlight_color_green = Color(0, 1, 0, 1) # bright green
var highlight_color_red = Color(1, 0, 0, 1)   # bright red
var grid_size = 8
var buildings = []

signal placed_building(building)

func _ready():
	pass

func _process(delta):
	if build_mode and selected_building_scene != null:
		if (selected_building == null):
			selected_building = selected_building_scene.instantiate()
			selected_building.preview_mode = true
			add_child(selected_building)
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = Vector2(
			snapped(mouse_pos.x, grid_size),
			snapped(mouse_pos.y, grid_size)
		)

		var size = selected_building.get_node("CollisionShape2D").shape.get_rect().size
		tile_highlight.size = size
		tile_highlight.global_position = snapped_pos - size / 2
		tile_highlight.visible = true
		selected_building.global_position = snapped_pos
		selected_building.visible = true

		if is_building_at_position(snapped_pos, size):
			tile_highlight.modulate = highlight_color_red
		else:
			tile_highlight.modulate = highlight_color_green

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = Vector2(
			snapped(mouse_pos.x, grid_size),
			snapped(mouse_pos.y, grid_size)
		)
		if build_mode:
			var building = selected_building_scene.instantiate()
			var size = building.get_node("CollisionShape2D").shape.get_rect().size
			if is_building_at_position(snapped_pos, size): 
				print("BuildingLayer: position occupied", snapped_pos)
				return
			else:
				place_building(snapped_pos, building)

func place_building(pos: Vector2i, building):
	selected_building.queue_free()
	building.global_position = pos
	tile_highlight.visible = false
	buildings.append(building)
	building.died.connect(_on_building_died)
	placed_building.emit(building)

func is_building_at_position(pos: Vector2, size: Vector2) -> bool:
	var proposed_rect = Rect2(pos - size / 2, size)
	for building in buildings:
		var shape = building.get_node_or_null("CollisionShape2D")
		if shape and shape.shape:
			var bpos = building.global_position
			var bsize = shape.shape.get_rect().size
			var building_rect = Rect2(bpos - bsize / 2, bsize)
			if proposed_rect.intersects(building_rect):
				return true
	return false

func _on_building_died(building):
	await get_tree().process_frame
	buildings.erase(building)
