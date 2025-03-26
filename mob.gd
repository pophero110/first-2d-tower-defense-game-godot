extends CharacterBody2D

@export var health = 30
@export var max_health = 30
@onready var health_bar: ProgressBar = $HealthBar
signal health_changed(newHealth: int)
signal died
		
func _ready():
	$AnimatedSprite2D.play("move")
	
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
		$DeathSound.play()
		$AnimatedSprite2D.play("die")
		died.emit()
		get_parent().set_process(false)
		$AnimatedSprite2D.animation_finished.connect(_on_die_animation_finished)

func _on_die_animation_finished():
	get_parent().queue_free() # Remove mob and also PathFollow2D
	
func update_health_bar_color():
	# Ensure health_bar is valid
	if !health_bar:
		return
	
	# Calculate health percentage
	var health_percentage = float(health) / max_health * 100
	
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
