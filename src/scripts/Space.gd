extends WorldEnvironment

var changing := false
var _on := true:
	set(value):
		_on = value
		changing = true
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _on:
		if changing:
			environment.ambient_light_energy = lerp(environment.ambient_light_energy, 0.8, 0.1)
			if is_equal_approx(environment.ambient_light_energy, 0.8):
				environment.ambient_light_energy = 0.8
				changing = false
	else:
		if changing:
			environment.ambient_light_energy = lerp(environment.ambient_light_energy, 0.3, 0.1)
			if is_equal_approx(environment.ambient_light_energy, 0.3):
				environment.ambient_light_energy = 0.3
				changing = false
