extends CharacterBody2D

@export var projectile_scene: PackedScene
@export var move_speed = 5000
@export var attack_range = 100

@onready var health_bar = $HeathBar
@onready var attack_timer = $AttackTimer
@onready var shooter = $Shooter
@onready var muzzle = $Shooter/Muzzle
@onready var agent = $NavigationAgent2D

var player: Node2D
var attack_rate = 2.0

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
		return
	set_muzzle_to_front()
	look_at(player.global_position)
	match current_state:
		MOB_STATE.CHASE:
			chase_player(delta)
		MOB_STATE.ATTACK:
			attack_player(delta)
		
func chase_player(delta):
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < attack_range:  # Set your attack range threshold
		current_state = MOB_STATE.ATTACK
		return

	agent.set_target_position(player.global_position)
	if agent.is_navigation_finished(): return
	var next_path_position = agent.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_position) * move_speed * delta
	if agent.avoidance_enabled:
		agent.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
	move_and_slide()

func attack_player(delta):
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player >= attack_range:
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

func take_damage(amout):
	health_bar.take_damage(amout)
	
func _on_mob_died():
	$DeathSound.play()
	shooter.play("die")
	died.emit()
	get_parent().set_process(false)
	shooter.animation_finished.connect(_on_die_animation_finished)
	
func _on_die_animation_finished():
	get_parent().queue_free() # Remove mob and also PathFollow2D

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity
