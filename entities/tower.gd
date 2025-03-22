extends Node2D

@export var projectile_scene: PackedScene
@export var attack_rate: float = 1  # Attack rate in seconds
@export var attack_range: float = 150  # Attack range in pixels

var enemies = []  # List of enemies within the attack range
var timer: Timer = null
var target: Node2D = null
var is_left_shoot: bool = true

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

# Called every frame to update the state
func _process(delta):
	# Update the list of enemies in the attack range
	enemies = get_tree().get_nodes_in_group("mob")
	# Find the closest target in range
	target = _find_target_in_range()
	# Rotate the tower towards the target if one exists
	if target:
		rotate_towards_target(target)
	else:
		reset_tower_rotation()

# Find the closest enemy within attack range
func _find_target_in_range() -> Node2D:
	var closest_enemy: Node2D = null
	var closest_distance: float = attack_range + 10  # Start with a value larger than the attack range
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		# If the enemy is within range and closer than the previous one, update the target
		if distance <= attack_range and distance < closest_distance:
			closest_enemy = enemy
			closest_distance = distance
	return closest_enemy

# Rotate the tower to face the target
func rotate_towards_target(target: Node2D):
	var direction = target.global_position - global_position
	rotation = direction.angle()

# Reset the tower's rotation if no target is found
func reset_tower_rotation():
	rotation = 0
	$AnimatedSprite2D.play("idle")  # Play idle animation

# Called when the attack timer times out
func _on_attack_timer_timeout():
	if target:
		attack()

# Perform the attack and switch shooting direction
func attack():
	# Alternate between left and right shooting animations
	if is_left_shoot:
		is_left_shoot = false
		$AnimatedSprite2D.play("left_shooting")
	else:
		is_left_shoot = true
		$AnimatedSprite2D.play("right_shooting")
	# Fire a projectile towards the target
	fire_projectile()

# Fire a projectile towards the target
func fire_projectile():
	var projectile = projectile_scene.instantiate()  # Create a new projectile instance
	get_parent().add_child(projectile)  # Add it to the scene
	projectile.position = position  # Set the projectile's position to the tower's position
	projectile.set_target(target)  # Pass the target to the projectile
