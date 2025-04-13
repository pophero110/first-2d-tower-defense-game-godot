extends TileMapLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	# Specify the condition under which you want to update the tile data.
	# For example, remove navigation from cell at (5, 10) on layer 0.
	return coords == Vector2i(5, 10)

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData):
	# Remove the navigation polygon by setting it to null.
	tile_data.set_navigation_polygon(0, null)
	return true
