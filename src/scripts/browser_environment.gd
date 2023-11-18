extends WorldEnvironment


var transition_completed := true
var target_energy := 0.58
var global: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not transition_completed:
		environment.ambient_light_energy = lerp(environment.ambient_light_energy,
												target_energy,
												0.1)
		if is_equal_approx(environment.ambient_light_energy, target_energy):
			environment.ambient_light_energy = target_energy
			transition_completed = true


func _on_browser_env_toggle(energy):
	target_energy = energy
	transition_completed = false
	print("browser environment toggled to %s" % target_energy)
