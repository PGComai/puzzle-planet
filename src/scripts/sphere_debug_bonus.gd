@tool
extends MeshInstance3D

@export var max_points = 500
@export var generations = 100
@export var max_border = 600
@export var border_factor = 30
@export var calc_border = true
@export var height_noise_frequency: float = 1.5
@export var mesh_resource: Resource
@export var border_offset := 0.1
@export var isphere_offset := 3.0
@export var isphere_radius := 3.0

@onready var piece = preload("res://scenes/planet_piece.tscn")
@onready var pieces = $"../Pieces"
@onready var camera_3d = $"../h/v/Camera3D"
@onready var txtmsh = preload("res://scenes/txtmsh.tscn")
var spheremesh = preload("res://scenes/bonus_minisphere.tscn")
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
#	while len(verts) < max_points:
#		verts = array_of_points(verts)
#		verts = shift_points(verts,0,1)
#	for x in generations:
#		verts = shift_points(verts,0,1)

	while len(verts) < max_points:
		verts = array_of_points(verts, false)
#		verts = shift_points(verts,0,1)
#	for x in generations:
#		verts = shift_points(verts,0,1)
	
	## numbermeshes
	for v in len(verts):
		var txt = txtmsh.instantiate()
		txt.mesh.text = str(v)
		txt.position = verts[v]*0.9
		add_child(txt)
	
	delaunay(verts)
		
	### MAKE BORDERS ###
		# border points should remember their 4 nearest main neighbors
#	var neighbor_dict: Dictionary
#	if calc_border:
#		while len(borderverts) < max_border:
#			borderverts = array_of_points(borderverts)
#			borderverts = shift_points(borderverts,0,1)
#		for x in generations:
#			borderverts = shift_points(borderverts,0,1)
#		for x in generations:
#			var bpush = border_push(borderverts, verts, x, generations)
#			borderverts = bpush[0]
#			neighbor_dict = bpush[1]
#			if x == generations-1:
#				pass
#			else:
#				borderverts = shift_points(borderverts, x, generations)
#
#	### SORT BORDERS ###
#	for v in len(verts):
#		vb_dict[v] = []
#	for v in len(verts):
#		for b in len(borderverts):
#			if verts[v] in neighbor_dict[b]:
#				vb_dict[v].append(b)
	# vb_dict assigns border vectors to each main vector
		
	draw_pointmesh(verts, newmesh)

#	var circle_idx = 0
#	var l = len(verts)
#	for v in l:
#		# sweep search axis is verts[v]
#		var amax = 2.0*PI
#		var border_array = PackedVector3Array()
#		var border_vecs = vb_dict[v]
#		var bvlen = len(border_vecs)
#		var order_arr = []
#		var order_dict = {}
#		if bvlen > 0:
#			var ref_b = borderverts[border_vecs[0]]-verts[v]
#			for bv in bvlen:
#				if bv == 0:
#					order_dict[0.0] = bv
#					order_arr.append(0.0)
#				else:
#					var ang = ref_b.signed_angle_to(borderverts[border_vecs[bv]]-verts[v], verts[v])
#					if ang < 0:
#						ang = (PI-abs(ang))+PI
#					order_arr.append(ang)
#					order_dict[ang] = bv
#		order_arr.sort()
#		#print(order_arr)
#		# now create an ordered array of border points
#		var proper_array = []
#		for ang in order_arr:
#			proper_array.append(order_dict[ang])
#		#print(proper_array)
#		# proper_array references the indices of each border point in border_vecs,
#		# which itself holds the indices of border points in borderverts
#		for i in proper_array:
#			border_array.append(borderverts[border_vecs[i]]+(verts[v]*border_offset))
#		border_array.append(borderverts[border_vecs[0]]+(verts[v]*border_offset))
#
#		### DRAW MESH ###
##
##			var surface_array = []
##			surface_array.resize(Mesh.ARRAY_MAX)
##
##			surface_array[Mesh.ARRAY_VERTEX] = border_array
##
##			newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, surface_array)
##			surface_array = []
##			surface_array.resize(Mesh.ARRAY_MAX)
#
#		draw_linemesh(border_array, newmesh)
			
	mesh = newmesh
			
#	for c in pieces.get_children():
#		c.visible = false

func delaunay(points: PackedVector3Array):
	var pls = []
	var good_triangles = []
	var num_of_points = len(points)
	var all_possible_threes = []
	for p in num_of_points:
		for p2 in num_of_points:
			for p3 in num_of_points:
				all_possible_threes.append([p,p2,p3])
	print(len(all_possible_threes))
	var sphere_done = false
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
				var plc = pl.get_center()
				var pl2c = pl2.get_center()

				var is_good = true
				var is_good2 = true

#				for pp in num_of_points:
#					if pl.is_point_over(points[pp]):
#						if abs(pl.distance_to(points[pp])) > 0.0005:
#							is_good = false
#					if pl2.is_point_over(points[pp]):
#						if abs(pl2.distance_to(points[pp])) > 0.0005:
#							is_good2 = false
				var center: Vector3
				for pp in num_of_points:
					center = plc + (pl.normal*isphere_offset)
					if points[pp].distance_to(center) < isphere_radius:
						if abs(pl.distance_to(points[pp])) > 0.0005:
							is_good = false
					center = pl2c + (pl2.normal*isphere_offset)
					if points[pp].distance_to(center) < isphere_radius:
						if abs(pl2.distance_to(points[pp])) > 0.0005:
							is_good2 = false

				var surface_array = []
				surface_array.resize(Mesh.ARRAY_MAX)
				if is_good:
					var off = plc.normalized()*0.0
					surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array([points[p]+off,points[p2]+off,points[p3]+off])
					surface_array[Mesh.ARRAY_NORMAL] = PackedVector3Array([pl.normal,pl.normal,pl.normal])
					newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
					good_triangles.append([p,p2,p3])
					var plarr = PackedVector3Array([points[p], points[p2], points[p3]])
					pls.append(plarr)
				if is_good2:
					var off = plc.normalized()*0.0
					
					surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array([points[p]+off,points[p3]+off,points[p2]+off])
					surface_array[Mesh.ARRAY_NORMAL] = PackedVector3Array([pl2.normal,pl2.normal,pl2.normal])
					newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
					good_triangles.append([p,p3,p2])
					var plarr = PackedVector3Array([points[p], points[p3], points[p2]])
					pls.append(plarr)
	print(len(good_triangles))
	#print(float(good_triangles)/float(num_of_points))
	
#########BONUS BITCHHH!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

func random_excluding(range: int, exc: Array):
	var result = randi_range(0, range-1)
	while result in exc:
		result = randi_range(0, range-1)
	return result

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

func array_of_points(arr: PackedVector3Array, ball = true):
	randomize()
	var rx = randfn(0.0, 2.0)
	var ry = randfn(0.0, 2.0)
	var rz = randfn(0.0, 2.0)
	if ball:
		arr.append(Vector3(rx, ry, rz).normalized())
	else:
		arr.append(Vector3(rx, ry, rz))
	return arr

func shift_points(vecs, gen, max_gen):
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
	
