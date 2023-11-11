extends MeshInstance3D

@onready var planet_piece = $".."
@onready var transparent = $"../transparent"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _orient_for_carousel():
	self.rotate_object_local(Vector3.UP, planet_piece.lon + PI)
	self.rotate_x(planet_piece.lat)
	transparent.rotate_object_local(Vector3.UP, planet_piece.lon + PI)
	transparent.rotate_x(planet_piece.lat)
