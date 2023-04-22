extends WorldEnvironment

var _on := false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _on:
		self.environment.ambient_light_energy = lerp(self.environment.ambient_light_energy, 1.0, 0.1)
	else:
		self.environment.ambient_light_energy = lerp(self.environment.ambient_light_energy, 0.13, 0.1)
