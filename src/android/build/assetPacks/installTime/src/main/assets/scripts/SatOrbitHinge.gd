extends Node3D

@export var orbit_speed := 1.0
@onready var sat_spin = $SatSpin

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotation.y -= delta * orbit_speed
	sat_spin.rotation.z += delta
