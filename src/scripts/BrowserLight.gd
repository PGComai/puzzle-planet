extends DirectionalLight3D


var transition_completed := true
var target_energy := 1.0
var global: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not transition_completed:
		light_energy = lerp(light_energy, target_energy, 0.1)
		if is_equal_approx(light_energy, target_energy):
			light_energy = target_energy
			transition_completed = true


func _on_browser_light_toggle(energy):
	target_energy = energy
	transition_completed = false
	print("browser light toggled to %s" % target_energy)
