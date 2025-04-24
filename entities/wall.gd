extends StaticBody2D

@onready var health_bar = $HealthBar
@export var preview_mode = false

signal died

# Called when the node enters the scene tree for the first time.
func _ready():
	if preview_mode:
		$AnimatedSprite2D.play("idle") # Optional: show idle animation in preview
		$HealthBar.visible = false
		for child in get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", true)
			elif child.has_node("CollisionShape2D"):
				child.get_node("CollisionShape2D").set_deferred("disabled", true)
		return
		
	health_bar.died.connect(_on_wall_destroyed)
	$AnimatedSprite2D.play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func take_damage(amout):
	health_bar.take_damage(amout)

func _on_wall_destroyed():
	$AnimatedSprite2D.play("die")
	$AnimatedSprite2D.animation_finished.connect(_on_die_animation_finished)
	
func _on_die_animation_finished():
	died.emit(self)
	queue_free()
