extends TileMapLayer

var prev_tile_pos: Vector2i = Vector2i(-1, -1)  # Stores last highlighted tile

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var tile_pos = local_to_map(get_local_mouse_position())  # Get hovered tile position
	var tileData = get_cell_tile_data(tile_pos)
	if (tileData == null): return
	if tile_pos != prev_tile_pos && tileData.get_custom_data("placable"):  # Only update if the tile changes
		set_cell(prev_tile_pos, 0, Vector2i(1,1))  # Remove previous highlight
		set_cell(tile_pos, 0, Vector2i(3, 2))  # Set highlight tile (adjust ID)
		prev_tile_pos = tile_pos
