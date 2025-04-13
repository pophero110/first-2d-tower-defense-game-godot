extends Control

var current_health: int
@export var max_health: int = 100
@onready var health_bar: Control = $HealthBar

signal died

func _ready():
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = max_health
	update_health_bar_color()

func _process(delta):
	health_bar.rotation = -get_parent().rotation
	health_bar.global_position = get_parent().global_position + Vector2(-25, -40)

func take_damage(amount: int) -> void:
	if current_health <= 0:
		print("Already dead")
		return

	current_health = max(current_health - amount, 0)
	health_bar.value = current_health
	update_health_bar_color()
	
	if current_health <= 0:
		died.emit()
	
func update_health_bar_color():
	if !health_bar:
		return
	var health_percentage = float(current_health) / max_health * 100
	
	# Duplicate the existing fill style
	var fill_style: StyleBoxFlat = health_bar.get_theme_stylebox("fill").duplicate()
	
	# Change color based on health percentage
	if health_percentage > 50:
		fill_style.bg_color = Color(0, 1, 0)  # Green
	elif health_percentage > 20:
		fill_style.bg_color = Color(1, 1, 0)  # Yellow
	else:
		fill_style.bg_color = Color(1, 0, 0)  # Red
	
	# Apply the new style to the health bar
	health_bar.add_theme_stylebox_override("fill", fill_style)
