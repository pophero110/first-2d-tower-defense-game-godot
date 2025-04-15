extends StaticBody2D

@onready var health_bar = $HealthBar

signal died

# Called when the node enters the scene tree for the first time.
func _ready():
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
