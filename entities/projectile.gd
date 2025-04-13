extends Area2D

@export var speed: float = 400  # Speed of the projectile
var projectile_type: String = "missle"
var target: Node2D  # The target to move towards
var damage: int = 0  # Damage dealt to the target
var hit_distance: int = 40

func _ready():
	if not target:
		queue_free()

func _initialize(enemy: Node2D = null, damage_value: int = 0, projectile_type: String = "missle"):
	self.target = enemy
	self.damage = damage_value
	self.projectile_type = projectile_type
	$AnimatedSprite2D.play(projectile_type)

func _process(delta):
	if target and is_instance_valid(target):
		var to_target = target.global_position - global_position
		var distance = to_target.length()

		if distance <= hit_distance:
			hit_target()
			return

		rotation = to_target.angle()

		var direction = to_target.normalized()	
		var velocity = direction * speed
		var movement = velocity * delta # Scaling
		# updates the position by adding the velocity (scaled by delta).
		position += movement
	else:
		queue_free()

func hit_target():
	if target and is_instance_valid(target):
		if projectile_type == "missle":
			missle_explode()
		else:
			target.take_damage(damage)
		queue_free()

func missle_explode():
	var explosion = preload("res://explosion_area.tscn").instantiate()
	explosion.global_position = target.global_position
	get_parent().add_child(explosion)
