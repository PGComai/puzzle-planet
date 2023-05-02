@tool
extends MeshInstance3D

@export var max_points = 500
@export var generations = 100
@export var max_border = 600
@export var border_factor = 30
@export var calc_border = true
@export var height_noise_frequency: float = 1.5
@export var mesh_resource: Resource
@export var border_offset := 0.0
@export var vertex_fill_threshold := 0.1
@export var vertex_merge_threshold := 0.05
@export var sub_triangle_recursion := 2

@onready var pieces = $"../Pieces"
@onready var camera_3d = $"../h/v/Camera3D"
@onready var txtmsh = preload("res://scenes/txtmsh.tscn")

var noise3d = FastNoiseLite.new()
var saver = ResourceSaver
var loader = ResourceLoader
var load_failed: bool = false
var looking: bool = false
var current_piece: MeshInstance3D
var fit_timer: float = 0.0
var fit: bool = false
var puzzle_fits: Dictionary
var placed_signal := false
var placed_timer := 0.0
var placed_counting := false
var newmesh = ArrayMesh.new()
var tricenters := PackedVector3Array()

# Called when the node enters the scene tree for the first time.
func _ready():
	noise3d.noise_type = 4
	noise3d.frequency = height_noise_frequency
	randomize()
	_generate_mesh()

func _process(delta):
	pass

func _generate_mesh():
	var verts: PackedVector3Array
	var borderverts: PackedVector3Array
	var colors: PackedColorArray
	var vb_dict: Dictionary
	
	### MAKE PUZZLE PIECE LOCATIONS ###
	while len(verts) < max_points:
		verts = array_of_points(verts)
		verts = shift_points(verts,0,1)
	for x in generations:
		verts = shift_points(verts,0,1)
		
	for v in len(verts):
		if verts[v].angle_to(Vector3.UP) < PI/32:
			print(v)
			print('angle to UP is:')
			print(verts[v].angle_to(Vector3.UP))
			var x = Vector3.UP.cross(verts[v]).normalized()
			verts[v] = verts[v].rotated(x, PI/32)
			print('new angle to UP is:')
			print(verts[v].angle_to(Vector3.UP))
		if verts[v].angle_to(Vector3.DOWN) < PI/32:
			print(v)
			print('angle to DOWN is:')
			print(verts[v].angle_to(Vector3.DOWN))
			var x = Vector3.DOWN.cross(verts[v]).normalized()
			verts[v] = verts[v].rotated(x, PI/32)
			print('new angle to DOWN is:')
			print(verts[v].angle_to(Vector3.DOWN))
	
	## numbermeshes
	for v in len(verts):
		var txt = txtmsh.instantiate()
		txt.mesh.text = str(v)
		txt.position = verts[v]*1.1
		add_child(txt)

	var delaunay_triangle_centers: Dictionary
	#delaunay(verts)
	delaunay_triangle_centers = delaunay(verts, true)

	var my_delaunay_points = verts_to_dpoints(verts, delaunay_triangle_centers)

	draw_pointmesh(verts, newmesh)
	
	var vi_to_borders = make_border_array(verts, my_delaunay_points)

	var newdict = fill_border_halfways(vi_to_borders.duplicate(true), verts)
	var newnewdict = fill_border_halfways(newdict.duplicate(true), verts)
	var newnewnewdict = fill_border_halfways(newnewdict.duplicate(true), verts)
#	_progressive_meshify_inwards(vi_to_borders, verts, newmesh, newnewnewdict)
	#_progressive_triangulate(vi_to_borders, verts, newmesh)
	
	for ndi in vi_to_borders.keys():
		draw_linemesh(vi_to_borders[ndi], newmesh)
		#delaunay(vi_to_borders[ndi])

	mesh = newmesh

func _progressive_triangulate(vbdict: Dictionary, og_verts: PackedVector3Array, msh: ArrayMesh):
	# needs to treat thin triangles differently while making same edge vertices
	var triangles = PackedVector3Array()
	var triangle_normals = PackedVector3Array()
	for bak in vbdict.keys():
		var border_array = vbdict[bak]
		var on = true
		var next_array = PackedVector3Array()
		for b in len(border_array)-1:
			var v0 = border_array[b]
			var v1 = border_array[b+1]
			var vp = og_verts[bak]
			#if v0.angle_to(vp) > vertex_fill_threshold and vp.angle_to(v1) > vertex_fill_threshold and v0.angle_to(v1) > vertex_fill_threshold:
			_sub_triangle(v0,vp,v1, triangles, triangle_normals)
#			_triangle(v0,vp,v1, triangles)
#			var n = Plane(v0,vp,v1).normal
#			_triangle(n,n,n, triangle_normals)
#			var newpoint: Vector3
#			var ang = v0.angle_to(vp)
#			var ax = v0.cross(vp).normalized()
#			newpoint = v0.rotated(ax, ang*0.2)
#			next_array.append(newpoint)
	draw_trimesh(triangles, triangle_normals, msh)

func _sub_triangle(p1: Vector3, p2: Vector3, p3: Vector3, arr: PackedVector3Array, normal_arr: PackedVector3Array, recursion := 0):
	var ang = p1.angle_to(p2)
	var ang2 = p2.angle_to(p3)
	var ang3 = p1.angle_to(p3)
	if recursion > sub_triangle_recursion:#(ang <= vertex_fill_threshold and ang2 <= vertex_fill_threshold and ang3 <= vertex_fill_threshold):
		_triangle(p1, p2, p3, arr)
		var n = Plane(p1, p2, p3).normal
		_triangle(n,n,n, normal_arr)
	else:
		recursion += 1
		var ax: Vector3
		var newpoint: Vector3
		var n: Vector3
		var angs = [ang, ang2, ang3]
		
		if true:#ang > vertex_fill_threshold and ang2 > vertex_fill_threshold and ang3 > vertex_fill_threshold:
			ax = p1.cross(p2).normalized()
			newpoint = p1.rotated(ax, ang*0.5)
			var p12 = newpoint
			
			ax = p2.cross(p3).normalized()
			newpoint = p2.rotated(ax, ang2*0.5)
			var p23 = newpoint
			
			ax = p1.cross(p3).normalized()
			newpoint = p1.rotated(ax, ang3*0.5)
			var p31 = newpoint
			
			_sub_triangle(p1, p12, p31, arr, normal_arr, recursion)
			
			_sub_triangle(p12, p2, p23, arr, normal_arr, recursion)
			
			_sub_triangle(p31, p23, p3, arr, normal_arr, recursion)
			
			_sub_triangle(p12, p23, p31, arr, normal_arr, recursion)
#		else:
#			var angtests = angs.map(func(number): return number > vertex_fill_threshold)
#			var num_short_edges = angtests.count(false)
#			print(num_short_edges)
#
#			if num_short_edges == 3 or num_short_edges == 2:
#				_triangle(p1, p2, p3, arr)
#				n = Plane(p1, p2, p3).normal
#				_triangle(n,n,n, normal_arr)
#			else:
#				var idx = angtests.find(false)
#				# call _sub_triangle on new triangle opposite short side
#				if idx == 0: # then the short side is p12
#					ax = p2.cross(p3).normalized()
#					newpoint = p2.rotated(ax, ang2*0.5)
#					var p23 = newpoint
#
#					ax = p1.cross(p3).normalized()
#					newpoint = p1.rotated(ax, ang3*0.5)
#					var p31 = newpoint
#
#					_sub_triangle(p31, p23, p3, arr, normal_arr, recursion)
#
#					_sub_triangle(p1, p23, p31, arr, normal_arr, recursion)
#
#					_sub_triangle(p23, p1, p2, arr, normal_arr, recursion)
#				elif idx == 1: # short side is p23
#					ax = p1.cross(p2).normalized()
#					newpoint = p1.rotated(ax, ang*0.5)
#					var p12 = newpoint
#
#					ax = p1.cross(p3).normalized()
#					newpoint = p1.rotated(ax, ang3*0.5)
#					var p31 = newpoint
#
#					_sub_triangle(p1, p12, p31, arr, normal_arr, recursion)
#
#					_sub_triangle(p12, p2, p31, arr, normal_arr, recursion)
#
#					_sub_triangle(p31, p2, p3, arr, normal_arr, recursion)
#				else: # short side is p31
#					ax = p1.cross(p2).normalized()
#					newpoint = p1.rotated(ax, ang*0.5)
#					var p12 = newpoint
#
#					ax = p2.cross(p3).normalized()
#					newpoint = p2.rotated(ax, ang2*0.5)
#					var p23 = newpoint
#
#					_sub_triangle(p12, p2, p23, arr, normal_arr, recursion)
#
#					_sub_triangle(p1, p12, p3, arr, normal_arr, recursion)
#
#					_sub_triangle(p3, p12, p23, arr, normal_arr, recursion)
				

func _triangle(p1: Vector3, p2: Vector3, p3: Vector3, arr: PackedVector3Array):
	arr.append(p1)
	arr.append(p2)
	arr.append(p3)

func _progressive_meshify_inwards(corner_dict: Dictionary, og_verts: PackedVector3Array, msh: ArrayMesh, ref_dict: Dictionary):
	var triangles = PackedVector3Array()
	var triangle_normals = PackedVector3Array()
	for cd in corner_dict.keys():
		var final_arr = PackedVector3Array()
		var border_array = corner_dict[cd]
		var new_border_array = PackedVector3Array()
		var new_border_array2 = PackedVector3Array()
		var new_border_array3 = PackedVector3Array()
		for b in border_array:
			var ang = b.angle_to(og_verts[cd])
			var ax = b.cross(og_verts[cd]).normalized()
			var newpoint = b.rotated(ax, ang*0.5)
			new_border_array.append(newpoint)
		new_border_array = fill_border_halfways_array(new_border_array)
		new_border_array = fill_border_halfways_array(new_border_array)
		new_border_array = fill_border_halfways_array(new_border_array)
		final_arr.append_array(new_border_array)
		draw_linemesh(new_border_array, msh)
		for b in border_array:
			var ang = b.angle_to(og_verts[cd])
			var ax = b.cross(og_verts[cd]).normalized()
			var newpoint = b.rotated(ax, ang*0.25)
			new_border_array2.append(newpoint)
		new_border_array2 = fill_border_halfways_array(new_border_array2)
		new_border_array2 = fill_border_halfways_array(new_border_array2)
		new_border_array2 = fill_border_halfways_array(new_border_array2)
		final_arr.append_array(new_border_array2)
		draw_linemesh(new_border_array2, msh)
		for b in border_array:
			var ang = b.angle_to(og_verts[cd])
			var ax = b.cross(og_verts[cd]).normalized()
			var newpoint = b.rotated(ax, ang*0.75)
			new_border_array3.append(newpoint)
		new_border_array3 = fill_border_halfways_array(new_border_array3)
		new_border_array3 = fill_border_halfways_array(new_border_array3)
		new_border_array3 = fill_border_halfways_array(new_border_array3)
		final_arr.append_array(new_border_array3)
		draw_linemesh(new_border_array3, msh)
#		for b in len(final_arr)-1:
#			var v0 = final_arr[b]
#			var v1 = final_arr[b+1]
#			var vp = og_verts[cd]
#			_triangle(v0,vp,v1, triangles)
#			var n = Plane(v0,vp,v1).normal
#			_triangle(n,n,n, triangle_normals)
	#draw_trimesh(triangles, triangle_normals, msh)

func verts_to_dpoints(og_verts: PackedVector3Array, dtc: Dictionary):
	var result = {}
	var l = len(og_verts)
	for v in l:
		result[v] = PackedVector3Array()
		for dtc_k in dtc.keys():
			if og_verts[v] in dtc_k:
				result[v].append(dtc[dtc_k])
	return result

func make_border_array(og_verts: PackedVector3Array, delaunay_points: Dictionary):
	var result = {}
	var l = len(og_verts)
	var newpoints = []
	for v in l:
		# sweep search axis is verts[v]
		var amax = 2.0*PI
		var border_array = PackedVector3Array()
		var border_vecs = delaunay_points[v]
		var bvlen = len(border_vecs)
		var order_arr = []
		var order_dict = {}
		if bvlen > 0:
			var ref_b = border_vecs[0]-og_verts[v]
			for bv in bvlen:
				if bv == 0:
					order_dict[0.0] = bv
					order_arr.append(0.0)
				else:
					var ang = ref_b.signed_angle_to(border_vecs[bv]-og_verts[v], og_verts[v])
					if ang < 0:
						ang = (PI-abs(ang))+PI
					order_arr.append(ang)
					order_dict[ang] = bv
		order_arr.sort()
		#print(order_arr)
		# now create an ordered array of border points
		var proper_array = []
		for ang in order_arr:
			proper_array.append(order_dict[ang])
		#print(proper_array)
		# proper_array references the indices of each border point in border_vecs,
		# which itself holds the indices of border points in borderverts
		for i in proper_array:
			border_array.append(border_vecs[i]+(og_verts[v]*border_offset))
		border_array.append(border_vecs[0]+(og_verts[v]*border_offset))
		result[v] = border_array
	return result
	
func fill_border_halfways_array(arr: Array):
	var new_border_array = PackedVector3Array()
	var skipnext := false
	for b in len(arr)-1:
		var plus1 = b+1
		if plus1 == len(arr) or skipnext:
			skipnext = false
		else:
			var current_border_point = arr[b]
			var next_border_point = arr[plus1]
			var ang = current_border_point.angle_to(next_border_point)
			var ax = current_border_point.cross(next_border_point).normalized()
#			if ang < vertex_merge_threshold:
#				print('merge')
#				var halfway = current_border_point.rotated(ax, ang/2.0)
#				new_border_array.remove_at(len(new_border_array)-1)
#				new_border_array.append(halfway)
#				skipnext = true
#			else:
			new_border_array.append(current_border_point)
			if ang > vertex_fill_threshold:
				var halfway = current_border_point.rotated(ax, ang/2.0)
				new_border_array.append(halfway)
			new_border_array.append(next_border_point)
		
	return new_border_array
	
func fill_border_halfways(vbdict: Dictionary, og_verts: PackedVector3Array):
	for vi in vbdict.keys():
		var border_array = vbdict[vi]
		var new_border_array = PackedVector3Array()
		for b in len(border_array)-1:
			var plus1 = b+1
			if plus1 == len(border_array):
				## last one
				pass
			else:
				var current_border_point = border_array[b]
				var next_border_point = border_array[plus1]
				var ang = current_border_point.angle_to(next_border_point)
				var ax = current_border_point.cross(next_border_point).normalized()
				new_border_array.append(current_border_point)
				if ang > vertex_fill_threshold:
					var halfway = current_border_point.rotated(ax, ang/2.0)
					new_border_array.append(halfway)
				new_border_array.append(next_border_point)
#		var replace_dict = {}
#		for b in len(new_border_array)-1:
#			var plus1 = b+1
#			if plus1 == len(new_border_array):
#				## last one
#				pass
#			else:
#				var current_border_point = new_border_array[b]
#				var next_border_point = new_border_array[plus1]
#				var ang = current_border_point.angle_to(next_border_point)
#				var ax = current_border_point.cross(next_border_point).normalized()
#				if ang < vertex_merge_threshold:
#					var halfway = current_border_point.rotated(ax, ang/2.0)
#					replace_dict[halfway] = [b, plus1]
#		print(replace_dict)
		vbdict[vi] = new_border_array
	return vbdict

func delaunay(points: PackedVector3Array, return_tris := false):
	var triangles = PackedVector3Array()
	var triangle_normals = PackedVector3Array()
	var tris = {}
	var centers = PackedVector3Array()
	var good_triangles = []
	var num_of_points = len(points)
	var all_possible_threes = []
	for p in num_of_points:
		for p2 in num_of_points:
			for p3 in num_of_points:
				all_possible_threes.append([p,p2,p3])
	#print(len(all_possible_threes))
	for three in all_possible_threes:
		var p = three[0]
		var p2 = three[1]
		var p3 = three[2]
		if p2 == p or points[p].angle_to(points[p2]) > PI/2 or p3 == p or p3 == p2 or points[p].angle_to(points[p3]) > PI/2 or points[p2].angle_to(points[p3]) > PI/2:
			pass
		else:
			## at this point we have three unique points
			var new = true
			for gt in good_triangles:
				if p in gt and p2 in gt and p3 in gt:
					new = false
			
			if !new:
				pass
			else:
				var pl = Plane(points[p],points[p2],points[p3])
				var pl2 = Plane(points[p],points[p3],points[p2])
				var plc = pl.get_center().normalized()
				
				var is_good = true
				var is_good2 = true

				for pp in num_of_points:
					if pl.is_point_over(points[pp]):
						if abs(pl.distance_to(points[pp])) > 0.0005:
							is_good = false
					if pl2.is_point_over(points[pp]):
						if abs(pl2.distance_to(points[pp])) > 0.0005:
							is_good2 = false
				var surface_array = []
				surface_array.resize(Mesh.ARRAY_MAX)
				
				# trying to merge points yet again
				
				for c in len(centers):
					if centers[c].angle_to(plc) < vertex_merge_threshold:
						plc = centers[c]
				
				if is_good:
					good_triangles.append([p,p2,p3])
					if !return_tris:
						#_sub_triangle(points[p], points[p2], points[p3], triangles, triangle_normals)
						_triangle(points[p], points[p2], points[p3], triangles)
						var n = Plane(points[p], points[p2], points[p3]).normal
						_triangle(n, n, n, triangle_normals)
#						var off = plc*0.0
#						surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array([points[p]+off,points[p2]+off,points[p3]+off])
#						newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
					else:
						var plarr = PackedVector3Array([points[p], points[p2], points[p3]])
						tris[plarr] = plc
						if !centers.has(plc):
							centers.append(plc)
				if is_good2:
					good_triangles.append([p,p3,p2])
					if !return_tris:
						#_sub_triangle(points[p], points[p3], points[p2], triangles, triangle_normals)
						_triangle(points[p], points[p3], points[p2], triangles)
						var n = Plane(points[p], points[p3], points[p2]).normal
						_triangle(n, n, n, triangle_normals)
#						var off = plc*0.0
#						surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array([points[p]+off,points[p3]+off,points[p2]+off])
#						newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
					else:
						var plarr = PackedVector3Array([points[p], points[p3], points[p2]])
						tris[plarr] = plc
						if !centers.has(plc):
							centers.append(plc)
	print(len(centers))
	print(len(tris))
	
	# another attempt to merge close points
#	var vertices_to_merge = Dictionary()
#	for c in centers:
#		for c1 in centers:
#			if c == c1:
#				pass
#			else:
#				var ang = c.angle_to(c1)
#				if ang >= vertex_merge_threshold:
#					pass
#				else:
#					var ax = c.cross(c1).normalized()
#					var newpoint = c.rotated(ax, ang/2.0)
#					vertices_to_merge[c] = newpoint
#					vertices_to_merge[c1] = newpoint
	#var newtris = tris.duplicate()
#	for plarr in tris.keys():
#		var no_double_vertices = []
#		if vertices_to_merge.has(tris[plarr]):
#			tris[plarr] = vertices_to_merge[tris[plarr]]
	
	
#	print(float(len(good_triangles))/float(num_of_points))
	if !return_tris:
		draw_trimesh(triangles, triangle_normals, newmesh)
	else:
		return tris

func random_excluding(range: int, exc: Array):
	var result = randi_range(0, range-1)
	while result in exc:
		result = randi_range(0, range-1)
	return result
	
func draw_trimesh(arr: PackedVector3Array, normal_arr: PackedVector3Array, msh: ArrayMesh):
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	surface_array[Mesh.ARRAY_VERTEX] = arr
	surface_array[Mesh.ARRAY_NORMAL] = normal_arr
	
	msh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)

func draw_pointmesh(arr: PackedVector3Array, msh: ArrayMesh):
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	surface_array[Mesh.ARRAY_VERTEX] = arr
	
	msh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, surface_array)
	
func draw_linemesh(arr: PackedVector3Array, msh: ArrayMesh):
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	surface_array[Mesh.ARRAY_VERTEX] = arr
	
	msh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, surface_array)

func array_of_points(arr: PackedVector3Array):
	randomize()
	var rx = randfn(0.0, 2.0)
	var ry = randfn(0.0, 2.0)
	var rz = randfn(0.0, 2.0)
	arr.append(Vector3(rx, ry, rz).normalized())
	return arr

func shift_points(vecs: PackedVector3Array, gen, max_gen):
	var progress = 1.0 - float(gen)/float(max_gen)
	for x in len(vecs):
		for y in len(vecs):
			if y != x:
				if vecs[x] == vecs[y]:
					vecs[x] = vecs[x].rotated((vecs[y].cross(vecs[x]).normalized()), deg_to_rad(-1))
				var sep = abs(vecs[x].angle_to(vecs[y]))
				vecs[y] = vecs[y].rotated((vecs[y].cross(vecs[x]).normalized()), deg_to_rad((-1/((sep + 1)*(sep + 1))))*progress)
	return vecs
	
func border_push(bordervecs, vecs, gen, max_gen):
	var nearest2 = []
	var neighbors = {}
	var record_neighbors = false
	if gen == max_gen-1:
		record_neighbors = true
	var progress = 1.0# - float(gen)/float(max_gen)
	for b in len(bordervecs):
		# find closest main vector
		var nearest = get_nearest_vec(bordervecs[b], vecs)
		if record_neighbors:
			neighbors[b] = nearest
		if nearest[0].angle_to(nearest[1]) < PI/32:
			pass
		else:
			var sep = abs(nearest[0].angle_to(bordervecs[b]))
			bordervecs[b] = bordervecs[b].rotated((bordervecs[b].cross(nearest[0]).normalized()), deg_to_rad((-1/((sep + 1)*(sep + 1))))*progress)
	return [bordervecs, neighbors]

func get_nearest_vec(vec, vecs: PackedVector3Array):
	var least = PI
	var angles = []
	var ref = {}
	var nearest: Vector3
	var nearest2: Vector3
	var nearest3: Vector3
	var nearest4: Vector3
	for v in vecs:
		if v == vec:
			pass
		else:
			var sep = abs(v.angle_to(vec))
			angles.append(sep)
			ref[sep] = v
			if sep < least:
				least = sep
				nearest = v
	var min_angle = angles.min()
	angles.erase(min_angle)
	nearest = ref[min_angle]
	var min_angle2 = angles.min()
	nearest2 = ref[min_angle2]
	angles.erase(min_angle)
	var min_angle3 = angles.min()
	nearest3 = ref[min_angle3]
	angles.erase(min_angle)
#	var min_angle4 = angles.min()
#	nearest4 = ref[min_angle4]
	return [nearest, nearest2, nearest3]
	
func mm(vec: Vector3):
	var offset = (noise3d.get_noise_3dv(vec))
	offset = clamp(remap(offset, -0.2, 0.2, 0.9, 1.1), 0.97, 1.5)
	return vec * offset
	
