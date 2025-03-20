extends Area2D

@export var speed: float = 200  # Speed of the projectile
var target: Node2D  # The target to move towards
var damage: int = 10  # Damage dealt to the target
var hit_distance: int = 40
# Set the target for the projectile to aim at
func set_target(enemy: Node2D):
	target = enemy

# Move towards the target in the _process method
func _process(delta):
	if target:
		$AnimatedSprite2D.play("idle")
		# Get direction to target
		var direction = target.global_position - global_position
		var distance = direction.length()
		
		if distance <= hit_distance:
			hit_target()
			return
		# Rotate the bullet to face the target
		rotation = direction.angle()
		# Move towards the target manually (apply velocity)
		position += Vector2(cos(rotation), sin(rotation)) * speed * delta

# Deal damage when hitting the target
func hit_target():
	target.take_damage(damage)
	queue_free()
