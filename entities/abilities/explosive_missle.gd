extends Node2D

@export var cooldown_in_seconds: int = 10
@export var duration_in_seconds: int = 5
@export var rank: String = "D" # TODO: best practice to create enum variable in GDScript
@export var tower: Node2D
@export var display_name = "Explosive Missle"
var ability_cooldown_progress_bar: ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
	if (tower == null): print("no tower link to this ability")
	
func _process(_delta):
	if !$CooldownTimer.is_stopped():
		ability_cooldown_progress_bar.value = $CooldownTimer.time_left
	else:
		ability_cooldown_progress_bar.value = cooldown_in_seconds
		
func isInCooldown():
	return !$CooldownTimer.is_stopped()
	
func deactiviate():
	print(display_name + " deactivated")
	tower.projectile_type = "shell"

func activate(cooldown_in_seconds):
	if ($CooldownTimer.is_stopped()):
		print(display_name + " activated")
		self.cooldown_in_seconds = cooldown_in_seconds
		$CooldownTimer.start(cooldown_in_seconds)
		$DurationTimer.start(duration_in_seconds)
		tower.projectile_type = "missle"

func _on_duration_timer_timeout():
	deactiviate()
