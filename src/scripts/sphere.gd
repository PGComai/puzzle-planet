extends Node3D

signal meshes_made
signal piece_placed(cidx)

@export var max_points = 500
@export var generations = 100
@export var max_border = 600
@export var border_factor = 30
@export var calc_border = true
@export var height_noise_frequency: float = 1.5
@export var save: bool = false
@export_enum('load', 'generate') var mesh_source: int = 1
@export var mesh_resource: Resource
@export var percent_complete: int = 50
@export_category('Colors')
@export var land_snow_color := Color('dbdbdb')
@export var land_green_color := Color('4a6c3f')
@export var sand_color := Color('9f876b')
@export var water_color := Color('0541ff')
@export var shallow_water_color := Color('2091bf')
@export var sand_threshold := 1.1
@export var water_offset := 1.09

@onready var piece = preload("res://scenes/planet_piece.tscn")
@onready var pieces = $"../Pieces"
@onready var save_template = preload("res://scripts/save_template.gd")
@onready var piece_target = $"../h/v/Camera3D/piece_target"
@onready var shadow_light = $"../h/v/Camera3D/piece_target/ShadowLight"
@onready var camera_3d = $"../h/v/Camera3D"
@onready var where = $where
@onready var sun = $"../Sun"
@onready var space = $"../Space"
@onready var sun_2 = $"../Sun2"

var noise3d = FastNoiseLite.new()
var saver = ResourceSaver
var loader = ResourceLoader
var load_failed: bool = false
var looking: bool = false
var current_piece: MeshInstance3D
var fit_timer: float = 0.0
var fit: bool = false
var puzzle_fits: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	noise3d.noise_type = 4
	noise3d.frequency = height_noise_frequency
	randomize()
	_generate_mesh()

func _process(delta):
	if looking:
		_piece_fit(delta)
	if fit_timer > 1.5:
		current_piece.reparent(pieces, false)
		current_piece.placed = true
		current_piece.position = Vector3.ZERO
		current_piece.rotation = Vector3.ZERO
		current_piece.global_position = piece_target.global_position
		fit = true
		looking = false
		fit_timer = 0.0
		shadow_light._on = false
		sun._on = true
		sun_2._on = true
		space._on = false
	if fit:
		current_piece.global_position = lerp(current_piece.global_position, current_piece.direction, 0.1)
		if current_piece.global_position.is_equal_approx(current_piece.direction):
			current_piece.global_position = current_piece.direction
			current_piece.remove_from_group('pieces')
			print('fitted')
			emit_signal("piece_placed", current_piece.circle_idx)
			fit = false
		

func _generate_mesh():
	var verts: PackedVector3Array
	var borderverts: PackedVector3Array
	var colors: PackedColorArray
	var vb_dict: Dictionary
	
	if mesh_source == 1:
		### MAKE PUZZLE PIECE LOCATIONS ###
		while len(verts) < max_points:
			verts = array_of_points(verts)
			verts = shift_points(verts,0,1)
		for x in generations:
			verts = shift_points(verts,0,1)
			
		### MAKE BORDERS ###
			# border points should remember their 4 nearest main neighbors
		var neighbor_dict: Dictionary
		if calc_border:
			while len(borderverts) < max_border:
				borderverts = array_of_points(borderverts)
				borderverts = shift_points(borderverts,0,1)
			for x in generations:
				borderverts = shift_points(borderverts,0,1)
			for x in generations:
				var bpush = border_push(borderverts, verts, x, generations)
				borderverts = bpush[0]
				neighbor_dict = bpush[1]
				if x == generations-1:
					pass
				else:
					borderverts = shift_points(borderverts, x, generations)
		
		### SORT BORDERS ###
		for v in len(verts):
			vb_dict[v] = []
		for v in len(verts):
			for b in len(borderverts):
				if verts[v] in neighbor_dict[b]:
					vb_dict[v].append(b)
		# vb_dict assigns border vectors to each main vector
		
		if save:
			var save_path = 'res://planets/'
			var save_number = len(DirAccess.get_files_at(save_path))+1
			var new_save = save_template.new()
			var save_name = 'planet' + str(save_number)
			new_save.verts = verts
			new_save.borderverts = borderverts
			new_save.vb_dict = vb_dict
			new_save.name = save_name
			saver.save(new_save, save_path+save_name+'.tres')
	
	elif mesh_source == 0:
		#if ResourceLoader.exists('res://planets/planet1.tres'):
		#print('loading')
		var loaded = mesh_resource
		verts = loaded.verts
		borderverts = loaded.borderverts
		vb_dict = loaded.vb_dict
		#else:
		#	load_failed = true
	
	if not load_failed:
		var circle_idx = 0
		var l = len(verts)
		for v in l:
			# sweep search axis is verts[v]
			var amax = 2.0*PI
			var border_array = PackedVector3Array()
			var border_vecs = vb_dict[v]
			var bvlen = len(border_vecs)
			var order_arr = []
			var order_dict = {}
			if bvlen > 0:
				var ref_b = borderverts[border_vecs[0]]-verts[v]
				for bv in bvlen:
					if bv == 0:
						order_dict[0.0] = bv
						order_arr.append(0.0)
					else:
						var ang = ref_b.signed_angle_to(borderverts[border_vecs[bv]]-verts[v], verts[v])
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
				border_array.append(borderverts[border_vecs[i]])
			border_array.append(borderverts[border_vecs[0]])
			
			### DRAW MESH ###
			
			var border_triangles = PackedVector3Array()
			var border_tri_normals = PackedVector3Array()
			var border_tri_colors = PackedColorArray()
			var water_triangles = PackedVector3Array()
			var water_tri_normals = PackedVector3Array()
			var water_tri_colors = PackedColorArray()
			var cutwater_triangles = PackedVector3Array()
			var cutwater_tri_normals = PackedVector3Array()
			var cutwater_tri_colors = PackedColorArray()
			var offset = 1.1
			#var edges_for_particles = []
			for b in len(border_array)-1:
				var v0 = border_array[b]
				var v1 = border_array[b+1]
				var v0p = mm(border_array[b]*offset)
				var v0pw = v0p.normalized()*water_offset
				var v0pw_depth = v0p.length_squared() - v0pw.length_squared()
				#edges_for_particles.append(v0p)
				var v1p = mm(border_array[b+1]*offset)
				var v1pw = v1p.normalized()*water_offset
				var v1pw_depth = v1p.length_squared() - v1pw.length_squared()
				#edges_for_particles.append(v1p)
				
				var vp = mm(verts[v]*offset)
				var vpw = vp.normalized()*water_offset
				var vpw_depth = vp.length_squared() - vpw.length_squared()
				var v0p2 = mm(v0p.move_toward(vp, v0p.distance_to(vp)/3).normalized()*offset)
				var v0p2w = v0p2.normalized()*water_offset
				var v0p2w_depth = v0p2.length_squared() - v0p2w.length_squared()
				var v1p2 = mm(v1p.move_toward(vp, v1p.distance_to(vp)/3).normalized()*offset)
				var v1p2w = v1p2.normalized()*water_offset
				var v1p2w_depth = v1p2.length_squared() - v1p2w.length_squared()
				var v0p3 = mm(v0p2.move_toward(vp, v0p2.distance_to(vp)/3).normalized()*offset)
				var v0p3w = v0p3.normalized()*water_offset
				var v0p3w_depth = v0p3.length_squared() - v0p3w.length_squared()
				var v1p3 = mm(v1p2.move_toward(vp, v1p2.distance_to(vp)/3).normalized()*offset)
				var v1p3w = v1p3.normalized()*water_offset
				var v1p3w_depth = v1p3.length_squared() - v1p3w.length_squared()
				var vp_color = land_green_color
				var v0p_color = land_green_color
				var v0p2_color = land_green_color
				var v0p3_color = land_green_color
				var v1p_color = land_green_color
				var v1p2_color = land_green_color
				var v1p3_color = land_green_color
				if vp.length() < sand_threshold:
					vp_color = sand_color
				elif asin(abs(vp.normalized().y)) > 0.9:
					vp_color = land_snow_color
				if v0p.length() < sand_threshold:
					v0p_color = sand_color
				elif asin(abs(v0p.normalized().y)) > 0.9:
					v0p_color = land_snow_color
				if v0p2.length() < sand_threshold:
					v0p2_color = sand_color
				elif asin(abs(v0p2.normalized().y)) > 0.9:
					v0p2_color = land_snow_color
				if v0p3.length() < sand_threshold:
					v0p3_color = sand_color
				elif asin(abs(v0p3.normalized().y)) > 0.9:
					v0p3_color = land_snow_color
				if v1p.length() < sand_threshold:
					v1p_color = sand_color
				elif asin(abs(v1p.normalized().y)) > 0.9:
					v1p_color = land_snow_color
				if v1p2.length() < sand_threshold:
					v1p2_color = sand_color
				elif asin(abs(v1p2.normalized().y)) > 0.9:
					v1p2_color = land_snow_color
				if v1p3.length() < sand_threshold:
					v1p3_color = sand_color
				elif asin(abs(v1p3.normalized().y)) > 0.9:
					v1p3_color = land_snow_color
					
				var depth_start = 0.001
				var depth_end = 0.05
				
				var vpw_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-vpw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
				var v0pw_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v0pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
				var v1pw_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
				var v0p2w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v0p2w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
				var v1p2w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v1p2w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
				var v0p3w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v0p3w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
				var v1p3w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v1p3w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
				
				## PIECE WALLS BEGIN ## -----------------------------
				
				border_triangles.append(v0)
				border_triangles.append(v0p)
				border_triangles.append(v1)
				
				border_tri_colors.append(Color('3f3227'))
				border_tri_colors.append(Color('3f3227'))
				border_tri_colors.append(Color('3f3227'))
				
				var n = Plane(v0,v0p,v1).normal
				border_tri_normals.append(n)
				border_tri_normals.append(n)
				border_tri_normals.append(n)
				
				###
				
				border_triangles.append(v1)
				border_triangles.append(v0p)
				border_triangles.append(v1p)
				
				border_tri_colors.append(Color('3f3227'))
				border_tri_colors.append(Color('3f3227'))
				border_tri_colors.append(Color('3f3227'))
				
				n = Plane(v1,v0p,v1p).normal
				border_tri_normals.append(n)
				border_tri_normals.append(n)
				border_tri_normals.append(n)
				
				cutwater_triangles.append(v0p.limit_length(water_offset))
				cutwater_triangles.append(v0pw.lerp(vp, 0.001))
				cutwater_triangles.append(v1p.limit_length(water_offset))
				
				cutwater_tri_colors.append(v0pw_color.lerp(Color('black'), clamp(remap(clamp(-v0pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0)))
				cutwater_tri_colors.append(v0pw_color)
				cutwater_tri_colors.append(v1pw_color.lerp(Color('black'), clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0)))
				
				n = Plane(v0p,v0pw,v1p).normal
				cutwater_tri_normals.append(n)
				cutwater_tri_normals.append(n)
				cutwater_tri_normals.append(n)
				
				###
				
				cutwater_triangles.append(v1p.limit_length(water_offset))
				cutwater_triangles.append(v0pw.lerp(vp, 0.001))
				cutwater_triangles.append(v1pw.lerp(vp, 0.001))
				
				cutwater_tri_colors.append(v1pw_color.lerp(Color('black'), clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0)))
				cutwater_tri_colors.append(v0pw_color)
				cutwater_tri_colors.append(v1pw_color)
				
				n = Plane(v1p,v0pw,v1pw).normal
				cutwater_tri_normals.append(n)
				cutwater_tri_normals.append(n)
				cutwater_tri_normals.append(n)
				
				## PIECE WALLS END ## -----------------------------
				
				## PIECE TOP BEGIN ## -----------------------------
				
				border_triangles.append(v0p)
				border_triangles.append(v0p2)
				border_triangles.append(v1p)
				
				border_tri_colors.append(v0p_color)
				border_tri_colors.append(v0p2_color)
				border_tri_colors.append(v1p_color)
				
				n = Plane(v0p,v0p2,v1p).normal
				border_tri_normals.append(v0p.normalized())
				border_tri_normals.append(v0p2.normalized())
				border_tri_normals.append(v1p.normalized())
				
				water_triangles.append(v0pw)
				water_triangles.append(v0p2w)
				water_triangles.append(v1pw)
				
				water_tri_colors.append(v0pw_color)
				water_tri_colors.append(v0p2w_color)
				water_tri_colors.append(v1pw_color)
				
				n = Plane(v0pw,v0p2w,v1pw).normal
				water_tri_normals.append(v0pw.normalized())
				water_tri_normals.append(v0p2w.normalized())
				water_tri_normals.append(v1pw.normalized())
				
				###
				
				border_triangles.append(v1p)
				border_triangles.append(v0p2)
				border_triangles.append(v1p2)
				
				border_tri_colors.append(v1p_color)
				border_tri_colors.append(v0p2_color)
				border_tri_colors.append(v1p2_color)
				
				n = Plane(v1p,v0p2,v1p2).normal
				border_tri_normals.append(v1p.normalized())
				border_tri_normals.append(v0p2.normalized())
				border_tri_normals.append(v1p2.normalized())
				
				water_triangles.append(v1pw)
				water_triangles.append(v0p2w)
				water_triangles.append(v1p2w)
				
				water_tri_colors.append(v1pw_color)
				water_tri_colors.append(v0p2w_color)
				water_tri_colors.append(v1p2w_color)
				
				n = Plane(v1pw,v0p2w,v1p2w).normal
				water_tri_normals.append(v1pw.normalized())
				water_tri_normals.append(v0p2w.normalized())
				water_tri_normals.append(v1p2w.normalized())
				
				###
				
				border_triangles.append(v0p2)
				border_triangles.append(v0p3)
				border_triangles.append(v1p2)

				border_tri_colors.append(v0p2_color)
				border_tri_colors.append(v0p3_color)
				border_tri_colors.append(v1p2_color)

				n = Plane(v0p2,v0p3,v1p2).normal
				border_tri_normals.append(v0p2.normalized())
				border_tri_normals.append(v0p3.normalized())
				border_tri_normals.append(v1p2.normalized())
				
				water_triangles.append(v0p2w)
				water_triangles.append(v0p3w)
				water_triangles.append(v1p2w)

				water_tri_colors.append(v0p2w_color)
				water_tri_colors.append(v0p3w_color)
				water_tri_colors.append(v1p2w_color)

				n = Plane(v0p2w,v0p3w,v1p2w).normal
				water_tri_normals.append(v0p2w.normalized())
				water_tri_normals.append(v0p3w.normalized())
				water_tri_normals.append(v1p2w.normalized())
				
				###
				
				border_triangles.append(v1p2)
				border_triangles.append(v0p3)
				border_triangles.append(v1p3)

				border_tri_colors.append(v1p2_color)
				border_tri_colors.append(v0p3_color)
				border_tri_colors.append(v1p3_color)

				n = Plane(v1p2,v0p3,v1p3).normal
				border_tri_normals.append(v1p2.normalized())
				border_tri_normals.append(v0p3.normalized())
				border_tri_normals.append(v1p3.normalized())
				
				water_triangles.append(v1p2w)
				water_triangles.append(v0p3w)
				water_triangles.append(v1p3w)

				water_tri_colors.append(v1p2w_color)
				water_tri_colors.append(v0p3w_color)
				water_tri_colors.append(v1p3w_color)

				n = Plane(v1p2w,v0p3w,v1p3w).normal
				water_tri_normals.append(v1p2w.normalized())
				water_tri_normals.append(v0p3w.normalized())
				water_tri_normals.append(v1p3w.normalized())
				
				###
				
				border_triangles.append(v0p3)
				border_triangles.append(vp)
				border_triangles.append(v1p3)

				border_tri_colors.append(v0p3_color)
				border_tri_colors.append(vp_color)
				border_tri_colors.append(v1p3_color)

				n = Plane(v0p3,vp,v1p3).normal
				border_tri_normals.append(v0p3.normalized())
				border_tri_normals.append(vp.normalized())
				border_tri_normals.append(v1p3.normalized())
				
				water_triangles.append(v0p3w)
				water_triangles.append(vpw)
				water_triangles.append(v1p3w)

				water_tri_colors.append(v0p3w_color)
				water_tri_colors.append(vpw_color)
				water_tri_colors.append(v1p3w_color)

				n = Plane(v0p3w,vpw,v1p3w).normal
				water_tri_normals.append(v0p3w.normalized())
				water_tri_normals.append(vpw.normalized())
				water_tri_normals.append(v1p3w.normalized())
				
				## PIECE TOP END ## -----------------------------
				
				## PIECE BOTTOM BEGIN ## -----------------------------
				
				border_triangles.append(v1)
				border_triangles.append(verts[v])
				border_triangles.append(v0)
				
				border_tri_colors.append(Color('3f3227'))
				border_tri_colors.append(Color('3f3227'))
				border_tri_colors.append(Color('3f3227'))
				
				n = -Plane(v0,verts[v],v1).normal
				border_tri_normals.append(n)
				border_tri_normals.append(n)
				border_tri_normals.append(n)
				
				## PIECE BOTTOM END ## -----------------------------
			
			var dxu = verts[v].cross(Vector3.UP)
			var up = dxu.rotated(verts[v].normalized(), -PI/2)
			
			var newpiece = piece.instantiate()
			newpiece.vertex = border_triangles
			newpiece.normal = border_tri_normals
			newpiece.color = border_tri_colors
			newpiece.vertex_w = water_triangles
			newpiece.normal_w = water_tri_normals
			newpiece.color_w = water_tri_colors
			newpiece.vertex_cw = cutwater_triangles
			newpiece.normal_cw = cutwater_tri_normals
			newpiece.color_cw = cutwater_tri_colors
			newpiece.direction = verts[v]
			puzzle_fits[v] = verts[v]
			newpiece.idx = v
			newpiece.siblings = l
			newpiece.ready_for_launch.connect(_on_ready_for_launch)
			newpiece.upright_vec = up.normalized()
			#newpiece.particle_edges = edges_for_particles
			# checking who stays
			var dieroll = randi_range(0, 99)
			if dieroll < percent_complete:
				newpiece.remove_from_group('pieces')
				newpiece.staying = true
			else:
				newpiece.circle_idx = circle_idx
				circle_idx += 1
			
			pieces.add_child(newpiece)
			
#	for c in pieces.get_children():
#		c.visible = false
	emit_signal("meshes_made")

func array_of_points(arr: PackedVector3Array):
	randomize()
	var rx = randfn(0.0, 2.0)
	var ry = randfn(0.0, 2.0)
	var rz = randfn(0.0, 2.0)
	arr.append(Vector3(rx, ry, rz).normalized())
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
	var min_angle2 = angles.min()
	nearest2 = ref[min_angle2]
	angles.erase(min_angle)
	var min_angle3 = angles.min()
	nearest3 = ref[min_angle3]
	angles.erase(min_angle)
	var min_angle4 = angles.min()
	nearest4 = ref[min_angle4]
	return [nearest, nearest2, nearest3, nearest4]
	
func mm(vec: Vector3):
	var offset = (noise3d.get_noise_3dv(vec))
	offset = clamp(remap(offset, -0.2, 0.2, 0.9, 1.1), 0.97, 1.5)
	return vec * offset
	
func _piece_fit(delta):
	if current_piece.global_position.normalized().angle_to(current_piece.direction.normalized()) < PI/32:
		#print('beep!')
		fit_timer += delta
	#where.position = current_piece.direction
	
func _on_ready_for_launch(_idx):
	var _pieces = get_tree().get_nodes_in_group('pieces')
	for p in _pieces:
		if p.idx == _idx:
			p.reparent(piece_target, false)
			current_piece = p
			p.position.y = -6.0
			p.in_space = true
			if !p.is_connected('take_me_home', _on_piece_take_me_home):
				p.take_me_home.connect(_on_piece_take_me_home)
			shadow_light._on = true
			space._on = true
			sun._on = false
			sun_2._on = false
			looking = true
			
func _on_piece_take_me_home(_idx):
	shadow_light._on = false
	space._on = false
	sun._on = true
	sun_2._on = true
	looking = false
