extends StaticBody2D

@onready var health_bar = $HealthBar

# Called when the node enters the scene tree for the first time.
func _ready():
	health_bar.died.connect(_on_wall_destroyed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func take_damage(amout):
	health_bar.take_damage(amout)

func _on_wall_destroyed():
	print("wall destroyed")
