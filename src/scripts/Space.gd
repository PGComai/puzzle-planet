extends WorldEnvironment

@onready var timer = $Timer

var changing := false
var _on := true:
	set(value):
		pass
#		_on = value
#		if value:
#			timer.stop()
#			changing = true
#		else:
#			timer.start()
#			changing = false
			#environment.ambient_light_energy = 0.8
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if changing:
		if _on:
			environment.ambient_light_energy = lerp(environment.ambient_light_energy, 0.8, 0.3)
			if is_equal_approx(environment.ambient_light_energy, 0.8):
				environment.ambient_light_energy = 0.8
				changing = false
		else:
			environment.ambient_light_energy = lerp(environment.ambient_light_energy, 0.3, 0.05)
			if is_equal_approx(environment.ambient_light_energy, 0.3):
				environment.ambient_light_energy = 0.3
				changing = false


func _on_timer_timeout():
	changing = true
