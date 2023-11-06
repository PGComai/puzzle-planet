@tool
extends MeshInstance3D

@onready var camera_3d = $"../h/v/Camera3D"

@export var number_of_stars: int = 1000
@export var radius: float = 5.0

var white_albedo = Color('ffffff')
var dark_albedo = Color('131313')

# Called when the node enters the scene tree for the first time.
func _ready():
	var arr_mesh = ArrayMesh.new()
	randomize()
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var colors = PackedColorArray()
	
	for star in range(number_of_stars):
		verts.append(Vector3(randfn(0,0.5),randfn(0,0.5),randfn(0,0.5)).normalized()*radius)
		var rg = randfn(0.9, 0.1)
		var b = randfn(0.8, 0.2)
		var a = randfn(0.5, 0.5)
		colors.append(Color(rg,rg,b).lerp(Color('black'), a))
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_COLOR] = colors

	# No blendshapes, lods, or compression used.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, surface_array)
	mesh = arr_mesh
	global_position = camera_3d.global_position
	visible = true
	
func _process(delta):
	global_position = camera_3d.global_position
