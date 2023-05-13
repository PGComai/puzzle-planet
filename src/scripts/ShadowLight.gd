extends DirectionalLight3D

var _on := false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _on:
		self.light_energy = lerp(self.light_energy, 0.8, 0.1)
	else:
		self.light_energy = lerp(self.light_energy, 0.0, 0.1)
