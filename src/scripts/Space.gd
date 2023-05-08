extends WorldEnvironment

var _on := true
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _on:
		self.environment.ambient_light_energy = lerp(self.environment.ambient_light_energy, 0.8, 0.1)
	else:
		self.environment.ambient_light_energy = lerp(self.environment.ambient_light_energy, 0.3, 0.1)
