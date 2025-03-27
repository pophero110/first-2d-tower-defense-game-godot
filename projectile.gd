extends Area2D

@export var speed: float = 400  # Speed of the projectile
var target: Node2D  # The target to move towards
var damage: int = 0  # Damage dealt to the target
var hit_distance: int = 40

func _initialize(enemy: Node2D = null, damage: int = 0):
	self.target = enemy
	self.damage = damage

func _process(delta):
	if target:
		var to_target = target.global_position - global_position
		var distance = to_target.length()
		
		if distance <= hit_distance:
			hit_target()
			return
		# Rotate the bullet to face the target
		rotation = to_target.angle()
		
		# Calculate the direction vector based on the current rotation
		var direction = to_target.normalized()		
		var velocity = direction * speed
		var movement = velocity * delta # Scaling
		# updates the position by adding the velocity (scaled by delta).
		position += movement
	else:
		queue_free()
		
func hit_target():
	target.take_damage(damage)
	queue_free()
	
