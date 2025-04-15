extends ProgressBar

var current_health: int
@export var health_bar_pos_offset: Vector2 = Vector2(-25, -40)
@export var health_bar_size: Vector2i = Vector2i(48, 5)
@export var max_health: int = 100

signal died

func _ready():
	current_health = max_health
	max_value = max_health
	value = max_health
	update_health_bar_color()
	size = health_bar_size

func _process(delta):
	rotation = -get_parent().rotation
	global_position = get_parent().global_position + health_bar_pos_offset

func take_damage(amount: int) -> void:
	if current_health <= 0:
		print("Already dead")
		return

	current_health = max(current_health - amount, 0)
	value = current_health
	update_health_bar_color()
	
	if current_health <= 0:
		died.emit()
	
func update_health_bar_color():
	var health_percentage = float(current_health) / max_health * 100
	
	# Duplicate the existing fill style
	var fill_style: StyleBoxFlat = get_theme_stylebox("fill").duplicate()
	
	# Change color based on health percentage
	if health_percentage > 50:
		fill_style.bg_color = Color(0, 1, 0)  # Green
	elif health_percentage > 20:
		fill_style.bg_color = Color(1, 1, 0)  # Yellow
	else:
		fill_style.bg_color = Color(1, 0, 0)  # Red
	
	# Apply the new style to the health bar
	add_theme_stylebox_override("fill", fill_style)
