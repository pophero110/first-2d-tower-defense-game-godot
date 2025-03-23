extends CharacterBody2D

@export var health = 100
@onready var health_bar: ProgressBar = $HealthBar
signal health_changed(newHealth: int)
		
func _ready():
	$AnimatedSprite2D.play()
	health_bar.max_value = health
	health_bar.value = health
	update_health_bar_color()
	
func _process(_delta):
	health_bar.rotation = -get_parent().rotation
	# TODO: make position dynamically based on mob size and healthbar size
	# TODO: make health bar size scale with mob size
	health_bar.global_position = get_parent().global_position + Vector2(-25, -40)

func take_damage(amount):
	health -= amount
	health_bar.value = health
	update_health_bar_color()
	health_changed.emit(health)
	if health <= 0:
		queue_free()
		
func update_health_bar_color():
	var fill_style: StyleBoxFlat = health_bar.get_theme_stylebox("fill").duplicate()
	if health > 50:
		fill_style.bg_color = Color(0, 1, 0)  # Green
	elif health > 20:
		fill_style.bg_color = Color(1, 1, 0)  # Yellow
	else:
		fill_style.bg_color = Color(1, 0, 0)  # Red
	
	health_bar.add_theme_stylebox_override("fill", fill_style)
