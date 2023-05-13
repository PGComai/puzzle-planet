extends MeshInstance3D

@onready var planet_piece = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	if planet_piece.mesh_arrange:
		#print('yo')
		self.rotate_object_local(Vector3.UP, planet_piece.lon + PI)
		self.rotate_x(planet_piece.lat)
		
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
