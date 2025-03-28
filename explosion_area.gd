extends Area2D

@export var damage: int = 10
@export var hit: bool = false

func _ready():
	$AnimatedSprite2D.play("explosion")
	
func _process(_delta):
	if not hit:
		apply_damage()

func apply_damage():
	var bodies = get_overlapping_bodies()
	print(bodies)
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			hit = true

func _on_animated_sprite_2d_animation_finished():
	queue_free()
