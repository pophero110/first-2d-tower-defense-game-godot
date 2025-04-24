extends Node2D

var highlight := false
var radius := 50
var base_color := Color(0, 0, 0, 0)
var highlight_color := Color(0.5, 0.7, 1.0, 0.2) # Transparent yellow

func _draw():
	if highlight:
		draw_circle(Vector2.ZERO, radius, highlight_color)
	else:
		draw_circle(Vector2.ZERO, radius, base_color)

func set_highlight_color(color: Color):
	highlight_color = color
	queue_redraw()
	
func set_highlight(value: bool):
	highlight = value
	queue_redraw()

func _ready():
	queue_redraw()
