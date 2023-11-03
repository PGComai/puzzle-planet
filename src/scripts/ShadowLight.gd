extends DirectionalLight3D

signal make_piece_visible

@onready var timer = $Timer

var changing := false
var _on := false:
	set(value):
		_on = value
#		changing = true
		if value:
			timer.start()
			changing = false
			#light_energy = 0.0
		else:
			timer.stop()
			changing = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if changing:
		if _on:
			light_energy = lerp(light_energy, 0.8, 0.05)
			if is_equal_approx(light_energy, 0.8):
				light_energy = 0.8
				changing = false
				timer.stop()
		else:
			light_energy = lerp(light_energy, 0.0, 0.1)
			if is_equal_approx(light_energy, 0.0):
				light_energy = 0.0
				changing = false
				timer.stop()


func _on_timer_timeout():
	emit_signal("make_piece_visible")
	changing = true
