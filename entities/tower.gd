extends Node2D

@export var projectile_scene: PackedScene
var attack_rate = 1  # in second
var attack_range = 200

var enemies = []  # Stores enemies inside the attack range
var timer = null
var target = null

func _draw():
	draw_circle(Vector2.ZERO, attack_range, Color(1, 0, 0, 0.3))
	
# Called when the node enters the scene tree for the first time.
func _ready():
	# Create firing timer
	timer = Timer.new()
	timer.wait_time = attack_rate
	timer.autostart = true
	timer.timeout.connect(_on_attack_timer_timeout)
	add_child(timer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Get all enemies from the enemies group
	enemies = get_tree().get_nodes_in_group("mob")
	# Find valid target in range
	target = _find_target_in_range()
	# Rotate tower to face target if we have one
	if target:
		var direction = target.global_position - global_position
		rotation = direction.angle()

func _find_target_in_range():
	var closest_enemy = null
	var closest_distance = attack_range + 10 # Start with something larger than range
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		# Check if this enemy is in range and closer than previously found enemies
		if distance <= attack_range and distance < closest_distance:
			closest_enemy = enemy
			closest_distance = distance
	return closest_enemy

func _on_attack_timer_timeout():
	if (target):
		attack()
func attack():
	fire_projectile(target)

# Fire a projectile towards the target
func fire_projectile(target):
	var projectile = projectile_scene.instantiate()  # Create a new projectile
	get_parent().add_child(projectile)  # Add it to the scene
	projectile.position = position  # Set the projectile's position to the tower's position
	projectile.set_target(target)  # Pass the target to the projectile
	
