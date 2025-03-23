extends Node2D

@export var cooldownInSeconds: int = 10
@export var durationInSeconds: int = 2
@export var rank: String = "E" # TODO: best practice to create enum variable in GDScript
var tower: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	$CooldownTimer.wait_time = cooldownInSeconds
	$DurationTimer.wait_time = durationInSeconds
	if (tower == null): print("no tower link to this ability")

func isInCooldown():
	return !$CooldownTimer.is_stopped()
	
func deactiviate():
	print("Rapid Fire deactivated")
	tower.adjust_attack_rate(tower.attack_rate * 2)

func activate():
	if ($CooldownTimer.is_stopped()):
		print("Rapid Fire activated")
		$CooldownTimer.start()
		$DurationTimer.start()
		tower.adjust_attack_rate(tower.attack_rate / 2)

func _on_cooldown_timer_timeout():
	activate()

func _on_duration_timer_timeout():
	deactiviate()
