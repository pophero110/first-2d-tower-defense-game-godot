extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var health = 200
var max_heatlh = 200

signal player_died

func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * SPEED
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.rotation = velocity.angle()
	else:
		$AnimatedSprite2D.stop()
	move_and_collide(velocity * delta)

func take_damage(amount):
	if health <= 0:
		print("PLayer is already dead")
		return
	health -= amount
	print("health: ", health)
	if health <= 0:
		player_died.emit()
		get_parent().set_process(false)
