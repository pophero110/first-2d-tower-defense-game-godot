extends CharacterBody2D

@export var projectile_scene: PackedScene
@export var move_speed = 30000
@export var attack_range = 150
@export var detect_range = 1000

@onready var health_bar = $HeathBar
@onready var attack_timer = $AttackTimer
@onready var shooter = $Shooter
@onready var muzzle = $Shooter/Muzzle
@onready var agent: NavigationAgent2D = $NavigationAgent2D

var player: Node2D = null
var attack_rate = 2.0
var current_target = null
var locked_blocking_target = null

signal died

var current_state = MOB_STATE.CHASE

enum MOB_STATE {
	CHASE,
	ATTACK
}
		
func _ready():
	shooter.play("move")
	health_bar.died.connect(_on_mob_died)

func _process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	if is_target_reachable(player):
		locked_blocking_target = null
		current_target = player
	else:
		if locked_blocking_target == null or is_target_reachable(locked_blocking_target):
			locked_blocking_target = find_blocking_building()
		current_target = locked_blocking_target
		
	assert(current_target != null)
		
	look_at(current_target.global_position)
	set_muzzle_to_front()

	match current_state:
		MOB_STATE.CHASE:
			chase_target(delta)
		MOB_STATE.ATTACK:
			attack_target(delta)
		
func chase_target(delta):
	var distance_to_target = global_position.distance_to(current_target.global_position)
	if distance_to_target < attack_range:  # Set your attack range threshold
		current_state = MOB_STATE.ATTACK
		return

	agent.set_target_position(current_target.global_position)
	if agent.is_navigation_finished(): return
	var next_path_position = agent.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_position) * move_speed * delta
	if agent.avoidance_enabled:
		agent.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
	move_and_slide()

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity

func is_target_reachable(target: Node2D) -> bool:
	agent.set_target_position(target.global_position)
	agent.get_next_path_position()
	return agent.is_target_reachable()

func find_blocking_building() -> Node2D:
	var buildings = get_tree().get_nodes_in_group("building")
	var nearest_building: Node2D = null
	var min_distance = INF

	for building in buildings:
		var dist_to_building = global_position.distance_to(building.global_position)
		if dist_to_building < min_distance:
			min_distance = dist_to_building
			nearest_building = building

	return nearest_building
	
func attack_target(delta):
	var distance_to_target = global_position.distance_to(current_target.global_position)
	if distance_to_target >= attack_range:
		current_state = MOB_STATE.CHASE
		shooter.play("move")
	elif attack_timer.is_stopped():
		attack_timer.start(attack_rate)
		play_shoot_animation()
		fire_projectile()
		
func set_muzzle_to_front():
	# Calculate a position in front of the mob based on its rotation
	var offset = Vector2(30, 15).rotated(rotation)
	# Position the muzzle in front of the mob and align its rotation
	muzzle.global_position = global_position + offset
	muzzle.rotation = rotation
	
func fire_projectile():
	var projectile = projectile_scene.instantiate()  # Create a new projectile instance
	projectile._initialize(current_target, 20, "bullet")
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

func take_damage(amout):
	health_bar.take_damage(amout)
	
func _on_mob_died():
	$DeathSound.play()
	shooter.play("die")
	died.emit()
	set_process(false)
	set_physics_process(false)
	shooter.animation_finished.connect(_on_die_animation_finished)
	
func _on_die_animation_finished():
	queue_free()


# === find nearest target based on detect range
#func _process(delta):
	#if current_target == null or not is_instance_valid(current_target):
		#current_target = find_nearest_target()
		#
	#if current_target == null:
		#return  # No target found, skip processing
		#
	#if is_target_reachable(current_target):
		#locked_blocking_target = null
	#else:
		#if locked_blocking_target == null or is_target_reachable(locked_blocking_target):
			#locked_blocking_target = find_blocking_building()
		#current_target = locked_blocking_target
	#
	#look_at(current_target.global_position)
	#set_muzzle_to_front()
#
	#match current_state:
		#MOB_STATE.CHASE:
			#chase_target(delta)
		#MOB_STATE.ATTACK:
			#attack_target(delta)
#
#func find_nearest_target() -> Node2D:
	#var all_targets = get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("building")
	#var nearest: Node2D = null
	#var min_dist = detect_range
	#
	#for target in all_targets:
		#if not is_instance_valid(target): continue
		#var dist = global_position.distance_to(target.global_position)
		#if dist <= min_dist:
			#min_dist = dist
			#nearest = target
	#
	#return nearest
