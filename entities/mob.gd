extends CharacterBody2D

@export var health = 30
@export var max_health = 30
@export var projectile_scene: PackedScene
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_timer = $AttackTimer
@onready var shooter = $Shooter
@onready var muzzle = $Shooter/Muzzle

var player: Node2D
var attack_rate = 2.0

signal health_changed(newHealth: int)
signal died

var current_state = MOB_STATE.CHASE

enum MOB_STATE {
	CHASE,
	ATTACK
}
		
func _ready():
	shooter.play("move")
	health_bar.max_value = max_health
	health_bar.value = health
	update_health_bar_color()
	
func _process(delta):
	# Keep the health bar upright and positioned above the mob
	health_bar.rotation = -rotation
	health_bar.global_position = global_position + Vector2(-25, -40)

	# Calculate a position in front of the mob based on its rotation
	var offset = Vector2(30, 0).rotated(rotation)
	
	# Position the muzzle in front of the mob and align its rotation
	muzzle.global_position = global_position + offset
	muzzle.rotation = rotation
	
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
		
	look_at(player.global_position)
	match current_state:
		MOB_STATE.CHASE:
			chase_player(delta)
		MOB_STATE.ATTACK:
			attack_player(delta)
		
func chase_player(delta):
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < 200:  # Set your attack range threshold
		current_state = MOB_STATE.ATTACK
		return

	var direction = (player.global_position - global_position).normalized()
	position += direction * 100 * delta

func attack_player(delta):
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player >= 200:
		current_state = MOB_STATE.CHASE
		shooter.play("move")
	elif attack_timer.is_stopped():
		attack_timer.start(attack_rate)
		play_shoot_animation()
		fire_projectile()
		
func fire_projectile():
	var projectile = projectile_scene.instantiate()  # Create a new projectile instance
	projectile._initialize(player, 20, "bullet")
	get_parent().add_child(projectile)  # Add it to the scene
	projectile.position = muzzle.global_position

func play_shoot_animation():
	var frame_count = shooter.get_sprite_frames().get_frame_count("shoot")
	var fsp = shooter.get_sprite_frames().get_animation_speed("shoot")
	var animation_duration = fsp / frame_count
	shooter.frame = 0  # Start from the first frame
	shooter.speed_scale = animation_duration / attack_rate
	shooter.play("shoot")
	$MuzzleFlash.play("muzzle_flash")

func take_damage(amount):
	if health <= 0:
		print("Mob is already dead")
		return
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
