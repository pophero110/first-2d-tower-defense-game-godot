extends Node2D

@export var projectile_scene: PackedScene
@export var attack_rate: float = 1  # Attack rate in seconds
@export var attack_range: float = 150  # Attack range in pixels
@onready var detectorCollisionCircle = $Detector/CollisionShape2D

var enemies = []  # List of enemies within the attack range3r
var timer: Timer = null
var target: Node2D = null
var ability: Node2D = null

# Draw the attack range as a red circle
func _draw():
	draw_circle(Vector2.ZERO, attack_range, Color(1, 0, 0, 0.3))

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize and set up the attack timer
	timer = Timer.new()
	timer.wait_time = attack_rate
	timer.autostart = true
	timer.timeout.connect(_on_attack_timer_timeout)
	add_child(timer)
	
	ability = preload("res://rapid_fire.tscn").instantiate()
	ability.tower = self
	add_child(ability)
	
	detectorCollisionCircle.shape.radius = attack_range

# Called every frame to update the state
func _process(_delta):
	if !enemies.is_empty():
		target = enemies.front()
		rotate_towards_target()
	else:
		target = null
		reset_tower_rotation()

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

func reset_tower_rotation():
	rotation = 0

func _on_attack_timer_timeout():
	if target:
		attack()

func attack():
	ability.activate()
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
	var projectile = projectile_scene.instantiate()  # Create a new projectile instance
	get_parent().add_child(projectile)  # Add it to the scene
	projectile.position = position  # Set the projectile's position to the tower's position
	projectile.set_target(target)  # Pass the target to the projectile

func adjust_attack_rate(new_attack_rate: float):
	self.attack_rate = new_attack_rate
	timer.wait_time = self.attack_rate

func _on_detector_body_entered(body):
	enemies.append(body)

func _on_detector_body_exited(body):
	enemies.erase(body)
