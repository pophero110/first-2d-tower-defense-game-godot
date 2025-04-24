extends Node2D

@export var projectile_scene: PackedScene
@export var attack_rate: float = 1  # Attack rate in seconds
@export var attack_range: float = 150  # Attack range in pixels
@export var attack_damage: float = 10
@export var projectile_type: String =  "shell"
@export var number_of_projectile: int = 1
@export var ability: Node = null
@export var ability_cooldown_in_seconds: float = 10
@onready var detector_collision_shape = $Detector/CollisionShape2D
@onready var ability_cooldown_progress_bar = $AbilityCooldownProgressBar
@onready var health_bar = $HealthBar

var enemies = []  # List of enemies within the attack range3r
var timer: Timer = null
var target: Node2D = null
@export var preview_mode = false

signal died

# Draw the attack range as a red circle
func _draw():
	if preview_mode or !is_inside_tree():
		draw_circle(Vector2.ZERO, attack_range, Color(1, 1, 1, 0.05))
	detector_collision_shape.shape.radius = attack_range

# Called when the node enters the scene tree for the first time
func _ready():
	if preview_mode:
		$AnimatedSprite2D.play("idle") # Optional: show idle animation in preview
		$HealthBar.visible = false
		$AbilityCooldownProgressBar.visible = false
		$Detector.set_deferred("monitoring", false)
		for child in get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", true)
			elif child.has_node("CollisionShape2D"):
				child.get_node("CollisionShape2D").set_deferred("disabled", true)
		return
	
	$Detector.visible = false
	# Initialize and set up the attack timer
	timer = Timer.new()
	timer.wait_time = attack_rate
	timer.autostart = true
	timer.timeout.connect(_on_attack_timer_timeout)
	add_child(timer)
	health_bar.died.connect(_on_tower_died)
	#ability.ability_cooldown_progress_bar = ability_cooldown_progress_bar
	#ability.tower = self
	#ability_cooldown_progress_bar.value = ability_cooldown_in_seconds
	#ability_cooldown_progress_bar.max_value = ability_cooldown_in_seconds

# Called every frame to update the state
func _process(_delta):
	if preview_mode:
		return
	# TODO: potential optimazation
	ability_cooldown_progress_bar.rotation = -rotation
	ability_cooldown_progress_bar.global_position = global_position + Vector2(-40, 40)
	enemies = enemies.filter(func(enemy): return enemy.health_bar.current_health > 0)
	if (enemies.is_empty()):
		target = null
		reset_tower_rotation()
	else: 
		target = enemies.front()
		rotate_towards_target()

# Find the closest enemy within attack range
#func _find_target_in_range() -> Node2D:
	#enemies = get_tree().get_nodes_in_group("mob")
	#var closest_enemy: Node2D = null
	#var closest_distance: float = attack_range + 10  # Start with a value larger than the attack range
	#for enemy in enemies:
		#var distance = global_position.distance_to(enemy.global_position)
		## If the enemy is within range and closer than the previous one, update the target
		#if distance <= attack_range and distance < closest_distance:
			#closest_enemy = enemy
			#closest_distance = distance
	#return closest_enemy

func rotate_towards_target():
	var direction = target.global_position - global_position
	rotation = direction.angle()
	# negate parent's rotation to avoid baking NavigationRegion2D incorrectly
	$CollisionShape2D.rotation = -rotation

func reset_tower_rotation():
	rotation = 0
	# reset to avoid baking NavigationRegion2D incorrectly
	$CollisionShape2D.rotation = 0 

func _on_attack_timer_timeout():
	timer.wait_time = self.attack_rate
	if target:
		attack()

func attack():
	$ShootSound.play()
	#ability.activate(ability_cooldown_in_seconds)
	fire_projectile()
	play_shoot_animation()

func play_shoot_animation():
	$AnimatedSprite2D.animation = "shoot"
	var frame_count = $AnimatedSprite2D.get_sprite_frames().get_frame_count("shoot")
	var fsp = $AnimatedSprite2D.get_sprite_frames().get_animation_speed("shoot")
	var animation_duration = fsp / frame_count
	$AnimatedSprite2D.frame = 0  # Start from the first frame
	$AnimatedSprite2D.speed_scale = animation_duration / attack_rate
	$AnimatedSprite2D.play()

func fire_projectile():
	var spacing = 30  # Adjust this value to control the spacing between projectiles
	for i in range(number_of_projectile):
		var projectile = projectile_scene.instantiate()  # Create a new projectile instance
		projectile._initialize(target, attack_damage, projectile_type)
		get_parent().add_child(projectile)  # Add it to the scene
		
		# Offset each projectile's position to prevent overlapping
		projectile.position = position + Vector2(i * spacing - (number_of_projectile - 1) * spacing / 2, 0)

func _on_detector_body_entered(body):
	enemies.append(body)

func _on_detector_body_exited(body):
	enemies.erase(body)

func take_damage(amout):
	health_bar.take_damage(amout)
	
func _on_tower_died():
	queue_free()
