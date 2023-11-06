extends MeshInstance3D

var ar := ArrayMesh.new()
var trunk_chunk := PackedVector3Array([
	Vector3(0.01, 0.0, 0.0),
	Vector3(0.0, -0.01, 0.0),
	Vector3(-0.01, 0.0, 0.0),
	Vector3(0.0, 0.01, 0.0)
])
var leaves_chunk := PackedVector3Array([
	Vector3(0.015, 0.0, 0.0),
	Vector3(0.0, -0.015, 0.0),
	Vector3(-0.015, 0.0, 0.0),
	Vector3(0.0, 0.015, 0.0)
])
var trunk_steps := 2
var trunk_array := PackedVector3Array()
var trunk_normals := PackedVector3Array()
var trunk_colors := PackedColorArray()
var trunk_color := Color('4d3b2d')

var leaves_steps := 3
var leaves_array := PackedVector3Array()
var leaves_normals := PackedVector3Array()
var leaves_colors := PackedColorArray()
var leaves_color := Color('285214')
var leaves_color_2 := Color('4f752f')
var _color := true
var spawn_position: Vector3
var oriented := false
var leaf_curve_1 := preload("res://tex/tree_leaf_curve_1.tres")
var size_multiplier := 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	leaves_color = leaves_color.lerp(leaves_color_2, randf_range(0.0, 1.0))
	global_position = spawn_position
	var trunk_height = randfn(0.01, 0.001)
	var leaves_height = randfn(0.02, 0.001)
	size_multiplier = randfn(1.0, 0.1)
	
	_extrude_loop(trunk_chunk,
				trunk_steps,
				trunk_height,
				trunk_array,
				trunk_normals,
				_color,
				trunk_color,
				trunk_colors)
	
	_extrude_loop(leaves_chunk,
				leaves_steps,
				leaves_height,
				leaves_array,
				leaves_normals,
				_color,
				leaves_color,
				leaves_colors,
				trunk_height * trunk_steps,
				true,
				leaf_curve_1,
				true)
	
	var arrays := []
	var arrays_leaves := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = trunk_array
	arrays[Mesh.ARRAY_NORMAL] = trunk_normals
	arrays_leaves.resize(Mesh.ARRAY_MAX)
	arrays_leaves[Mesh.ARRAY_VERTEX] = leaves_array
	arrays_leaves[Mesh.ARRAY_NORMAL] = leaves_normals
	if _color:
		arrays[Mesh.ARRAY_COLOR] = trunk_colors
		arrays_leaves[Mesh.ARRAY_COLOR] = leaves_colors
	
	ar.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	ar.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_leaves)
	mesh = ar


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not oriented: ### turn this into a one-off signal
		look_at(global_position * 2.0, Vector3.UP, true)
		rotate_object_local(Vector3.FORWARD, randf_range(0.0, PI))
		oriented = true


func _extrude_loop(loop: PackedVector3Array,
				extrusion_steps: int,
				step_distance: float,
				vertex_array: PackedVector3Array,
				normal_array: PackedVector3Array,
				vertex_color := false,
				color := Color('white'),
				color_array := PackedColorArray(),
				offset := 0.0,
				follow_curve := false,
				curve := Curve.new(),
				close_top := false
				):
	for es in extrusion_steps:
		var offset_1 := Vector3(0.0, 0.0, step_distance * (es + 1) + offset)
		var offset_0 := Vector3(0.0, 0.0, step_distance * es + offset)
		var p: Plane
		var curve_multiplier_0 := 1.0
		var curve_multiplier_1 := 1.0
		var close := 1.0
		if es == extrusion_steps - 1 and close_top:
			close = 0.0
		if follow_curve:
			var curve_progress_0: float = remap(float(es),
										0.0, float(extrusion_steps - 1),
										0.0, 1.0)
			var curve_progress_1: float = remap(float(es + 1),
										0.0, float(extrusion_steps - 1),
										0.0, 1.0)
			curve_multiplier_0 = leaf_curve_1.sample_baked(curve_progress_0)
			curve_multiplier_1 = leaf_curve_1.sample_baked(curve_progress_1)
		for tri in loop.size():
			var i0 = tri
			var i1 = tri + 1
			if i1 == loop.size():
				i1 = 0
			
			var v1 = (loop[i0]
					* size_multiplier
					* curve_multiplier_0) + offset_0
			var v2 = (loop[i1]
					* size_multiplier
					* curve_multiplier_0) + offset_0
			var v3 = (loop[i0]
					* size_multiplier
					* curve_multiplier_1 * close) + lerp(offset_0,
														offset_1,
														close)
			vertex_array.append(v1)
			vertex_array.append(v2)
			vertex_array.append(v3)
			
			p = Plane(v1, v2, v3)
			normal_array.append(p.normal)
			normal_array.append(p.normal)
			normal_array.append(p.normal)
			
			v1 = (loop[i1]
				* size_multiplier *
				curve_multiplier_0) + offset_0
			v2 = (loop[i1]
				* size_multiplier *
				curve_multiplier_1 *
				close) + lerp(offset_0,
							offset_1,
							close)
			v3 = (loop[i0]
				* size_multiplier *
				curve_multiplier_1 *
				close) + lerp(offset_0,
							offset_1,
							close)
			vertex_array.append(v1)
			vertex_array.append(v2)
			vertex_array.append(v3)
			
			p = Plane(v1, v2, v3)
			normal_array.append(p.normal)
			normal_array.append(p.normal)
			normal_array.append(p.normal)
			
			if vertex_color:
				for i in 6:
					color_array.append(color)
