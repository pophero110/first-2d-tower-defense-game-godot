extends ProgressBar

@export var target: CharacterBody2D  # The mob to follow

func _ready():
	if target:
		max_value = target.health
		value = target.health
		update_health_bar_color()
		target.connect("health_changed", _on_target_health_changed)

# This function will be called when the target's health changes
func _on_target_health_changed(new_health: int):
	value = new_health
	update_health_bar_color()

func update_health(value: int):
	self.value = value
	update_health_bar_color()

func update_health_bar_color():
	var fill_style: StyleBoxFlat = get_theme_stylebox("fill").duplicate()
	if value > 50:
		fill_style.bg_color = Color(0, 1, 0)  # Green
	elif value > 20:
		fill_style.bg_color = Color(1, 1, 0)  # Yellow
	else:
		fill_style.bg_color = Color(1, 0, 0)  # Red
	
	add_theme_stylebox_override("fill", fill_style)
