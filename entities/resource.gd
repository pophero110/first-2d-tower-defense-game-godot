extends Area2D

@export var resource_type: String = "Tree"
@export var collect_time: float = 2.0
@export var resource_amount: int = 10
@export var collect_distance: float = 120.0

@onready var collect_timer: Timer = $CollectTimer
@onready var collect_bar: ProgressBar = $CollectBar
@onready var circle_visual = $CircleVisual

signal collected(resource_type: String, amount: int)

var player: Node2D = null
var player_collect_start_pos: Vector2 = Vector2.ZERO
var is_collecting: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	collect_bar.max_value = collect_time
	input_event.connect(_on_input_event)

func _process(_delta):
	if is_collecting:
		collect_bar.value = collect_time - collect_timer.time_left
		if player.global_position != player_collect_start_pos:
			cancel_collection()

func start_collection():
	player_collect_start_pos = player.global_position
	is_collecting = true
	collect_timer.start(collect_time)

func cancel_collection():
	is_collecting = false
	collect_timer.stop()
	collect_bar.value = 0

func _on_collect_timer_timeout():
	is_collecting = false
	collected.emit(resource_type, resource_amount)
	queue_free()

func _on_mouse_entered():
	var distance = player.global_position.distance_to(global_position)
	if distance <= collect_distance:
		circle_visual.set_highlight_color(Color(0, 1, 0, 0.4)) # green
	else:
		circle_visual.set_highlight_color(Color(1, 0, 0, 0.4)) # red
	circle_visual.set_highlight(true)

func _on_mouse_exited():
	circle_visual.set_highlight(false)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_collecting:
			return
		if player.global_position.distance_to(global_position) <= collect_distance:
			start_collection()
