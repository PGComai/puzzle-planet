extends Node3D

signal meshes_made
signal piece_placed(cidx)

@export var debug := false
@export var max_points = 500
@export var generations = 100
@export var save: bool = false
@export_enum('load', 'generate') var mesh_source: int = 1
@export var mesh_resource: Resource
@export var pieces_at_start: int = 15
@export var piece_offset := 1.0
@export_category('Terrain')
@export var crust_thickness := 1.1
@export var vertex_fill_threshold := 0.1
@export var vertex_merge_threshold := 0.05
@export_range(1.0, 5.0, 2.0) var sub_triangle_recursion := 3
@export_enum('custom', 'earth', 'mars', 'moon') var planet_style := 0
@export var test_noise: FastNoiseLite
@export var height_noise_frequency: float = 1.5
@export var height_noise_type: FastNoiseLite.NoiseType
@export var height_noise_domain_warp := false
@export var domain_warp_amplitude := 30.0
@export var domain_warp_fractal_gain := 0.5
@export var domain_warp_fractal_lacunarity := 6.0
@export var domain_warp_fractal_octaves := 5
@export var domain_warp_fractal_type: FastNoiseLite.DomainWarpFractalType = 1
@export var domain_warp_frequency := 0.05
@export var domain_warp_type: FastNoiseLite.DomainWarpType = 0
@export var fractal_gain := 0.5
@export var fractal_lacunarity := 2.0
@export var fractal_octaves := 5
@export var fractal_ping_pong_strength := 2.0
@export var fractal_type: FastNoiseLite.FractalType = 1
@export var fractal_weighted_strength := 0.0
@export var ocean := true    
@export var snow := true 
@export_range(0,1) var snow_random_low := 0.85
@export_range(0,1) var snow_random_high := 0.95
@export_range(0,1) var min_terrain_height_unclamped := 0.9
@export_range(1,1.5) var max_terrain_height_unclamped := 1.1
@export_range(0,1) var min_terrain_height := 0.9
@export_range(1,1.5) var max_terrain_height := 1.5
@export var clamp_terrain := false
@export var invert_height := false
@export var craters := false
@export var crater_height_threshold := 1.05
@export_range(1, 100) var num_craters := 10
@export var crater_height_curve: Curve
@export_category('Colors')
@export var color_test := Color('Black')
@export var low_crust_color := Color('3f3227')
@export var crust_color := Color('3f3227')
@export var land_snow_color := Color('dbdbdb')
@export var land_color := Color('4a6c3f')
@export_range(0.0, 2.0) var land_color_threshold := 1.1
@export var land_color_2 := Color('4d6032')
@export_range(0.0, 2.0) var land_color_threshold_2 := 0.9
@export var land_color_3 := Color('5e724c')
@export var low_land_color := Color('74432e')
@export var low_land_bottom_threshold := 0.95
@export var low_land_top_threshold := 1.1
@export var sand_color := Color('9f876b')
@export var water_color := Color('0541ff')
@export var shallow_water_color := Color('2091bf')
@export var sand_threshold := 1.1
@export var water_offset := 1.09
@export var color_noise_frequency: float = 1.5
@export var color_noise_type: FastNoiseLite.NoiseType
@export var color_noise_domain_warp := false
@export var color_domain_warp_amplitude := 30.0
@export var color_domain_warp_fractal_gain := 0.5
@export var color_domain_warp_fractal_lacunarity := 6.0
@export var color_domain_warp_fractal_octaves := 5
@export var color_domain_warp_fractal_type: FastNoiseLite.DomainWarpFractalType = 1
@export var color_domain_warp_frequency := 0.05
@export var color_domain_warp_type: FastNoiseLite.DomainWarpType = 0
@export var color_fractal_gain := 0.5
@export var color_fractal_lacunarity := 2.0
@export var color_fractal_octaves := 5
@export var color_fractal_ping_pong_strength := 2.0
@export var color_fractal_type: FastNoiseLite.FractalType = 1
@export var color_fractal_weighted_strength := 0.0

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
@onready var atmo = $"../Atmo"
@onready var atmo_2 = $"../Atmo2"
@onready var mantle = $"../Mantle"
@onready var mantle_earth_material = preload("res://tex/mantle_earth_material.tres")
@onready var mantle_mars_material = preload("res://tex/mantle_mars_material.tres")
@onready var mantle_moon_material = preload("res://tex/mantle_moon_material.tres")
@onready var lava_lamp = $"../Lava Lamp"
@onready var moon_crater_curve = preload("res://tex/moon_crater_curve.tres")

var lava_lamp_color_earth = Color('f1572f')
var lava_lamp_color_mars = Color('c08333')

var noise3d = FastNoiseLite.new()
var colornoise = FastNoiseLite.new()
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
var snow_start: float
var max_distance_between_vecs := 0.000016
var global
var crater_array := []

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	if !(planet_style == 0) and !debug:
		planet_style = global.generate_type
		pieces_at_start = global.pieces_at_start
	randomize()
	colornoise.noise_type = 4
	colornoise.frequency = 2.0
	colornoise.seed = randi_range(0, 100000)
	colornoise.domain_warp_enabled = color_noise_domain_warp
	colornoise.domain_warp_amplitude = color_domain_warp_amplitude
	colornoise.domain_warp_fractal_gain = color_domain_warp_fractal_gain
	colornoise.domain_warp_fractal_lacunarity = color_domain_warp_fractal_lacunarity
	colornoise.domain_warp_fractal_octaves = color_domain_warp_fractal_octaves
	colornoise.domain_warp_fractal_type = color_domain_warp_fractal_type
	colornoise.domain_warp_frequency = color_domain_warp_frequency
	colornoise.domain_warp_type = color_domain_warp_type
	colornoise.fractal_gain = color_fractal_gain
	colornoise.fractal_lacunarity = color_fractal_lacunarity
	colornoise.fractal_octaves = color_fractal_octaves
	colornoise.fractal_ping_pong_strength = color_fractal_ping_pong_strength
	colornoise.fractal_type = color_fractal_type
	colornoise.fractal_weighted_strength = color_fractal_weighted_strength
	noise3d.noise_type = height_noise_type
	noise3d.frequency = height_noise_frequency
	noise3d.seed = randi_range(0, 100000)
	noise3d.domain_warp_enabled = height_noise_domain_warp
	noise3d.domain_warp_amplitude = domain_warp_amplitude
	noise3d.domain_warp_fractal_gain = domain_warp_fractal_gain
	noise3d.domain_warp_fractal_lacunarity = domain_warp_fractal_lacunarity
	noise3d.domain_warp_fractal_octaves = domain_warp_fractal_octaves
	noise3d.domain_warp_fractal_type = domain_warp_fractal_type
	noise3d.domain_warp_frequency = domain_warp_frequency
	noise3d.domain_warp_type = domain_warp_type
	noise3d.fractal_gain = fractal_gain
	noise3d.fractal_lacunarity = fractal_lacunarity
	noise3d.fractal_octaves = fractal_octaves
	noise3d.fractal_ping_pong_strength = fractal_ping_pong_strength
	noise3d.fractal_type = fractal_type
	noise3d.fractal_weighted_strength = fractal_weighted_strength
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
		if !placed_signal:
			current_piece.remove_from_group('pieces')
			placed_signal = true
			placed_counting = true
		current_piece.global_position = lerp(current_piece.global_position, current_piece.direction, 0.1)
		if current_piece.global_position.is_equal_approx(current_piece.direction):
			current_piece.global_position = current_piece.direction
			print('fitted')
			fit = false
			placed_signal = false
	if placed_counting:
		placed_timer += delta
		if placed_timer > 0.2:
			emit_signal("piece_placed", current_piece.circle_idx)
			placed_counting = false
			placed_timer = 0.0
		

func _generate_mesh():
	var verts := PackedVector3Array()
	var borderverts := PackedVector3Array()
	var colors := PackedColorArray()
	var vb_dict := Dictionary()
	var vi_to_borders := Dictionary()
	var recursed_borders := Dictionary()
	
	if mesh_source == 1:
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
		
		var delaunay_triangle_centers: Dictionary
		delaunay_triangle_centers = NEW_delaunay(verts, true)

		var my_delaunay_points = NEW_verts_to_dpoints(verts, delaunay_triangle_centers)
		
		vi_to_borders = make_border_array(verts, my_delaunay_points)
		
		## NEW STUFF
		
		recursed_borders = vi_to_borders.duplicate()
		var used_border_vecs = PackedVector3Array()
		for r in sub_triangle_recursion+1:
			recursed_borders = NEW_fill_border_halfways(recursed_borders.duplicate(), verts, used_border_vecs)

		## NEW STUFF

#		var newdict = fill_border_halfways(vi_to_borders.duplicate(true), verts)
#		var newnewdict = fill_border_halfways(newdict.duplicate(true), verts)
#		var newnewnewdict = fill_border_halfways(newnewdict.duplicate(true), verts)
		
		var circle_idx = 0
		var l = len(verts)
		
		if planet_style == 0:
			pass
			#test_noise.frequency = height_noise_frequency
			#noise3d = test_noise
			#colornoise = test_noise
		elif planet_style == 1:
			## override colors to earth style
			colornoise.noise_type = 4
			colornoise.frequency = 2.0
			colornoise.domain_warp_enabled = false
			colornoise.domain_warp_amplitude = 30
			colornoise.domain_warp_fractal_gain = 0.5
			colornoise.domain_warp_fractal_lacunarity = 6
			colornoise.domain_warp_fractal_octaves = 5
			colornoise.domain_warp_fractal_type = 1
			colornoise.domain_warp_frequency = 0.05
			colornoise.domain_warp_type = 0
			colornoise.fractal_gain = 0.5
			colornoise.fractal_lacunarity = 2
			colornoise.fractal_octaves = 5
			colornoise.fractal_ping_pong_strength = 2
			colornoise.fractal_type = 1
			colornoise.fractal_weighted_strength = 0
			noise3d.noise_type = 4
			noise3d.frequency = 1.5
			noise3d.domain_warp_enabled = false
			noise3d.domain_warp_amplitude = 30.0
			noise3d.domain_warp_fractal_gain = 0.5
			noise3d.domain_warp_fractal_lacunarity = 6.0
			noise3d.domain_warp_fractal_octaves = 5
			noise3d.domain_warp_fractal_type = 1
			noise3d.domain_warp_frequency = 0.05
			noise3d.domain_warp_type = 0
			noise3d.fractal_gain = 0.5
			noise3d.fractal_lacunarity = 2.0
			noise3d.fractal_octaves = 5
			noise3d.fractal_ping_pong_strength = 2.0
			noise3d.fractal_type = 1
			noise3d.fractal_weighted_strength = 0.0
			low_crust_color = Color('6e2e0c')
			crust_color = Color('3f3227')
			land_snow_color = Color('dbdbdb')
			land_color = Color('4a6c3f')
			land_color_threshold = 0.96
			land_color_2 = Color('4d6032')
			land_color_threshold = 0.94
			land_color_3 = Color('b3814c')
			low_land_color = Color('4a6c3f')
			low_land_bottom_threshold = 0.5
			low_land_top_threshold = 0.9
			sand_color = Color('9f876b')
			water_color = Color('0541ff')
			shallow_water_color = Color('2091bf')
			sand_threshold = 1.1
			water_offset = 1.09
			ocean = true
			snow_random_low = 0.85
			snow_random_high = 0.95
			max_terrain_height_unclamped = 1.34
			min_terrain_height_unclamped = 0.65
			max_terrain_height = 1.3
			min_terrain_height = 0.8
			clamp_terrain = false
			invert_height = false
			craters = false
			snow = true
			atmo.visible = true
			atmo_2.visible = true
			mantle.mesh.material = mantle_earth_material
			atmo.mesh.material.set_shader_parameter('Scattered_Color',Color('afc7ee'))
			atmo_2.mesh.material.set_shader_parameter('Scattered_Color',Color('afc7ee'))
			atmo.mesh.material.set_shader_parameter('sunset_color',Color('e5152a'))
			atmo_2.mesh.material.set_shader_parameter('sunset_color',Color('e5152a'))
			lava_lamp.light_color = lava_lamp_color_earth
			lava_lamp.visible = true
		elif planet_style == 2:
			## mars
			colornoise.noise_type = 4
			colornoise.frequency = 1.5
			colornoise.domain_warp_enabled = false
			colornoise.domain_warp_amplitude = 30
			colornoise.domain_warp_fractal_gain = 0.5
			colornoise.domain_warp_fractal_lacunarity = 6
			colornoise.domain_warp_fractal_octaves = 5
			colornoise.domain_warp_fractal_type = 1
			colornoise.domain_warp_frequency = 0.05
			colornoise.domain_warp_type = 0
			colornoise.fractal_gain = 0.5
			colornoise.fractal_lacunarity = 2
			colornoise.fractal_octaves = 5
			colornoise.fractal_ping_pong_strength = 2
			colornoise.fractal_type = 1
			colornoise.fractal_weighted_strength = 0
			noise3d.noise_type = 4
			noise3d.frequency = 3.0
			noise3d.domain_warp_enabled = false
			noise3d.domain_warp_amplitude = 0.052
			noise3d.domain_warp_fractal_gain = 0.285
			noise3d.domain_warp_fractal_lacunarity = 4.253
			noise3d.domain_warp_fractal_octaves = 5
			noise3d.domain_warp_fractal_type = 1
			noise3d.domain_warp_frequency = 0.05
			noise3d.domain_warp_type = 0
			noise3d.fractal_gain = 0.5
			noise3d.fractal_lacunarity = 2.0
			noise3d.fractal_octaves = 5
			noise3d.fractal_ping_pong_strength = 2.0
			noise3d.fractal_type = 1
			noise3d.fractal_weighted_strength = 0.0
			ocean = false
			snow_random_low = 0.976
			snow_random_high = 0.984
			max_terrain_height_unclamped = 1.01
			min_terrain_height_unclamped = 0.2
			max_terrain_height = 1.13
			min_terrain_height = 1.02
			clamp_terrain = true
			invert_height = true
			craters = false
			low_crust_color = Color('5e1c18')
			crust_color = Color('542b18')
			land_snow_color = Color('dbdbdb')
			land_color = Color('8c5323')
			land_color_threshold = 1.02
			land_color_2 = Color('6f4024')
			land_color_threshold_2 = 0.99
			land_color_3 = Color('423122')
			low_land_color = Color('74432e')
			low_land_bottom_threshold = 0.822
			low_land_top_threshold = 0.9
			sand_color = Color('9f876b')
			water_color = Color('0541ff')
			shallow_water_color = Color('2091bf')
			snow = true
			atmo.visible = true
			atmo_2.visible = true
			mantle.mesh.material = mantle_mars_material
			atmo.mesh.material.set_shader_parameter('Scattered_Color',Color('f3cfac'))
			atmo_2.mesh.material.set_shader_parameter('Scattered_Color',Color('f3cfac'))
			atmo.mesh.material.set_shader_parameter('sunset_color',Color('a3dbff'))
			atmo_2.mesh.material.set_shader_parameter('sunset_color',Color('a3dbff'))
			#lava_lamp.light_color = lava_lamp_color_mars
			lava_lamp.visible = true
		elif planet_style == 3:
			# moon
			colornoise.noise_type = 4
			colornoise.frequency = 2.0
			colornoise.domain_warp_enabled = false
			colornoise.domain_warp_amplitude = 30
			colornoise.domain_warp_fractal_gain = 0.5
			colornoise.domain_warp_fractal_lacunarity = 6
			colornoise.domain_warp_fractal_octaves = 5
			colornoise.domain_warp_fractal_type = 1
			colornoise.domain_warp_frequency = 0.05
			colornoise.domain_warp_type = 0
			colornoise.fractal_gain = 0.5
			colornoise.fractal_lacunarity = 2
			colornoise.fractal_octaves = 5
			colornoise.fractal_ping_pong_strength = 2
			colornoise.fractal_type = 1
			colornoise.fractal_weighted_strength = 0.735
			noise3d.noise_type = 4
			noise3d.frequency = 2.731
			noise3d.domain_warp_enabled = false
			noise3d.domain_warp_amplitude = 30.0
			noise3d.domain_warp_fractal_gain = 0.5
			noise3d.domain_warp_fractal_lacunarity = 6.0
			noise3d.domain_warp_fractal_octaves = 5
			noise3d.domain_warp_fractal_type = 1
			noise3d.domain_warp_frequency = 0.05
			noise3d.domain_warp_type = 0
			noise3d.fractal_gain = 0.5
			noise3d.fractal_lacunarity = 2.0
			noise3d.fractal_octaves = 5
			noise3d.fractal_ping_pong_strength = 2.0
			noise3d.fractal_type = 1
			noise3d.fractal_weighted_strength = 0.0
			low_crust_color = Color('292929')
			crust_color = Color('353535')
			land_snow_color = Color('dbdbdb')
			land_color = Color('737373')
			land_color_threshold = 1.011
			land_color_2 = Color('5b5b5b')
			land_color_threshold = 0.962
			land_color_3 = Color('464646')
			low_land_color = Color('242424')
			low_land_bottom_threshold = 0.911
			low_land_top_threshold = 1.254
			sand_color = Color('9f876b')
			water_color = Color('0541ff')
			shallow_water_color = Color('2091bf')
			sand_threshold = 1.1
			water_offset = 1.09
			ocean = false
			snow_random_low = 0.85
			snow_random_high = 0.95
			max_terrain_height_unclamped = 1.1
			min_terrain_height_unclamped = 0.882
			max_terrain_height = 1.092
			min_terrain_height = 0.43
			clamp_terrain = false
			invert_height = false
			snow = false
			craters = true
			crater_height_threshold = 1.137
			num_craters = 50
			crater_height_curve = moon_crater_curve
			mantle.mesh.material = mantle_moon_material
			atmo.visible = false
			atmo_2.visible = false
			lava_lamp.light_color = lava_lamp_color_earth
			lava_lamp.visible = false
			
		if snow_random_high > snow_random_low:
			snow_start = randf_range(snow_random_low, snow_random_high)
		elif snow_random_high == snow_random_low:
			snow_start = snow_random_high
		else:
			snow_start = 0.9
		
		craterize()
		
		var new_prog_tri = NEW_progressive_triangulate(vi_to_borders, verts, used_border_vecs)

	emit_signal("meshes_made")

func craterize():
	for cr in num_craters:
		var impact = Vector3(randfn(0.0, 1.0), randfn(0.0, 1.0), randfn(0.0, 1.0)).normalized()
		var strength = randfn(3.0, 2.0)
		crater_array.append([impact, strength])

func progressive_triangulate(border_array: PackedVector3Array, og_idx: int, og_verts: PackedVector3Array, used_border_vecs: PackedVector3Array):
	# treats thin triangles differently while making same edge vertices
	var border_triangles = PackedVector3Array()
	var border_tri_normals = PackedVector3Array()
	var border_tri_colors = PackedColorArray()
	var water_triangles = PackedVector3Array()
	var water_tri_normals = PackedVector3Array()
	var water_tri_colors = PackedColorArray()
	
	var arrays = [border_triangles, border_tri_normals, border_tri_colors,
		water_triangles, water_tri_normals, water_tri_colors]
	
	####
#	var triangles = PackedVector3Array()
#	var triangle_normals = PackedVector3Array()
	var used_vecs = PackedVector3Array()
	for b in len(border_array)-1:
		var v0 = border_array[b].snapped(Vector3(0.001, 0.001, 0.001))
		var v1 = border_array[b+1].snapped(Vector3(0.001, 0.001, 0.001))
		var vp = og_verts[og_idx].snapped(Vector3(0.001, 0.001, 0.001))
		for pt in used_border_vecs:
			if v0.distance_squared_to(pt) < max_distance_between_vecs:
				v0 = pt
				break
		for pt in used_border_vecs:
			if v1.distance_squared_to(pt) < max_distance_between_vecs:
				v1 = pt
				break
		for pt in used_border_vecs:
			if vp.distance_squared_to(pt) < max_distance_between_vecs:
				vp = pt
				break
		if !used_border_vecs.has(v0):
			used_border_vecs.append(v0)
		if !used_border_vecs.has(v1):
			used_border_vecs.append(v1)
		if !used_border_vecs.has(vp):
			used_border_vecs.append(vp)
		if !used_vecs.has(v0):
			used_vecs.append(v0)
		if !used_vecs.has(v1):
			used_vecs.append(v1)
		if !used_vecs.has(vp):
			used_vecs.append(vp)
		_sub_triangle(v0,vp,v1, arrays, used_vecs, used_border_vecs)
	#draw_trimesh(triangles, triangle_normals, msh)
	####
	
	return [border_triangles, border_tri_normals, border_tri_colors,
		water_triangles, water_tri_normals, water_tri_colors]

func NEW_progressive_triangulate(vbdict: Dictionary, og_verts: PackedVector3Array, used_border_vecs: PackedVector3Array):
	var pieces_stayed := 0
	var circle_idx := 0
	var newborders = vbdict.duplicate()
	for r in sub_triangle_recursion+1:
		newborders = NEW_fill_border_halfways(newborders.duplicate(), og_verts, used_border_vecs)
	for bak in vbdict.keys():
		var border_triangles = PackedVector3Array()
		var border_tri_normals = PackedVector3Array()
		var border_tri_colors = PackedColorArray()
		var water_triangles = PackedVector3Array()
		var water_tri_normals = PackedVector3Array()
		var water_tri_colors = PackedColorArray()
		
		var arrays = [border_triangles, border_tri_normals, border_tri_colors,
			water_triangles, water_tri_normals, water_tri_colors]
		var new_border_array = newborders[bak]
		var NEW_tess_result = NEW_tesselate(og_verts, bak, new_border_array, crust_thickness, used_border_vecs)
		var border_array = vbdict[bak]
		var on = true
		var used_vecs = PackedVector3Array()
		for b in len(border_array)-1:
			var v0 = border_array[b].snapped(Vector3(0.001, 0.001, 0.001))
			var v1 = border_array[b+1].snapped(Vector3(0.001, 0.001, 0.001))
			var vp = og_verts[bak].snapped(Vector3(0.001, 0.001, 0.001))
			for pt in used_border_vecs:
				if v0.distance_squared_to(pt) < max_distance_between_vecs:
					v0 = pt
					break
			for pt in used_border_vecs:
				if v1.distance_squared_to(pt) < max_distance_between_vecs:
					v1 = pt
					break
			for pt in used_border_vecs:
				if vp.distance_squared_to(pt) < max_distance_between_vecs:
					vp = pt
					break
			if !used_vecs.has(v0):
				used_vecs.append(v0)
			if !used_vecs.has(v1):
				used_vecs.append(v1)
			if !used_vecs.has(vp):
				used_vecs.append(vp)
			_sub_triangle(v0,vp,v1, arrays, used_vecs, used_border_vecs)
		var dxu = og_verts[bak].cross(Vector3.UP)
		var up = dxu.rotated(og_verts[bak].normalized(), -PI/2)
		
		var newpiece = piece.instantiate()
		newpiece.wall_vertex = NEW_tess_result[0]
		newpiece.wall_normal = NEW_tess_result[1]
		newpiece.wall_color = NEW_tess_result[2]
		newpiece.vertex = border_triangles
		newpiece.normal = border_tri_normals
		newpiece.color = border_tri_colors
		newpiece.ocean = ocean
		if ocean:
			newpiece.vertex_w = water_triangles
			newpiece.normal_w = water_tri_normals
			newpiece.color_w = water_tri_colors
			newpiece.vertex_cw = NEW_tess_result[3]
			newpiece.normal_cw = NEW_tess_result[4]
			newpiece.color_cw = NEW_tess_result[5]
		newpiece.direction = og_verts[bak]
		puzzle_fits[bak] = og_verts[bak]
		newpiece.idx = bak
		newpiece.siblings = len(og_verts)
		newpiece.ready_for_launch.connect(_on_ready_for_launch)
		newpiece.upright_vec = up.normalized()
		newpiece.orient_upright = !global.rotation
		#newpiece.particle_edges = edges_for_particles
		newpiece.offset = piece_offset
		# checking who stays
		if pieces_stayed < pieces_at_start:
			newpiece.remove_from_group('pieces')
			newpiece.staying = true
			pieces_stayed += 1
		else:
			newpiece.circle_idx = circle_idx
			circle_idx += 1
		
		pieces.add_child(newpiece)

func _sub_triangle(p1: Vector3, p2: Vector3, p3: Vector3, arrays: Array,
			used_vecs: PackedVector3Array,
			used_border_vecs: PackedVector3Array,
			recursion := 0,
			shade_min := 0,
			shade_max := 1,
			vsnap := 0.001):
#	[border_triangles, border_tri_normals, border_tri_colors,            0, 1, 2
#		water_triangles, water_tri_normals, water_tri_colors]            3, 4, 5
	if recursion > sub_triangle_recursion:
		# i think this is where we need to apply color, height, etc to vertices
		
		for pt in used_vecs:
			if p1.distance_squared_to(pt) < max_distance_between_vecs:
				p1 = pt
				break
		for pt in used_vecs:
			if p2.distance_squared_to(pt) < max_distance_between_vecs:
				p2 = pt
				break
		for pt in used_vecs:
			if p3.distance_squared_to(pt) < max_distance_between_vecs:
				p3 = pt
				break
		if !used_vecs.has(p1):
			used_vecs.append(p1)
		if !used_vecs.has(p2):
			used_vecs.append(p2)
		if !used_vecs.has(p3):
			used_vecs.append(p3)
		
		# land height
		p1 = mm(p1*crust_thickness)
		p2 = mm(p2*crust_thickness)
		p3 = mm(p3*crust_thickness)
		
		# land color
		var land_colors = [land_color, land_color_2, land_color_3]
		var p1_color = land_colors[color_vary(p1)].lerp(low_land_color, 1-clamp(remap(p1.length_squared(), pow(low_land_bottom_threshold, 2.0), pow(low_land_top_threshold, 2.0), 0.0, 1.0), 0.0, 1.0))
		var p2_color = land_colors[color_vary(p2)].lerp(low_land_color, 1-clamp(remap(p2.length_squared(), pow(low_land_bottom_threshold, 2.0), pow(low_land_top_threshold, 2.0), 0.0, 1.0), 0.0, 1.0))
		var p3_color = land_colors[color_vary(p3)].lerp(low_land_color, 1-clamp(remap(p3.length_squared(), pow(low_land_bottom_threshold, 2.0), pow(low_land_top_threshold, 2.0), 0.0, 1.0), 0.0, 1.0))
#		if craters:
#			var my_craters = []
#			for cr in crater_array:
#				var dist1 = p1.normalized().distance_squared_to(cr[0])
#				if dist1 <= cr[1] * 0.01:
#					var dist1_mapped = remap(dist1, 0.0, cr[1] * 0.01, 0.0, 1.0)
#					my_craters.append(dist1_mapped)
#				for mycr_i in len(my_craters):
#					newvec *= 1.0 + (crater_height_curve.sample(my_craters[mycr_i]) * 0.02 * ((mycr_i + 1) / len(my_craters)))
		if p1.length_squared() < pow(sand_threshold, 2) and ocean:
			p1_color = sand_color
		elif asin(abs(p1.normalized().y)) > snow_start and snow:
			p1_color = land_snow_color
		if p2.length_squared() < pow(sand_threshold, 2) and ocean:
			p2_color = sand_color
		elif asin(abs(p2.normalized().y)) > snow_start and snow:
			p2_color = land_snow_color
		if p3.length_squared() < pow(sand_threshold, 2) and ocean:
			p3_color = sand_color
		elif asin(abs(p3.normalized().y)) > snow_start and snow:
			p3_color = land_snow_color
		
		# water height
		var p1w = p1.normalized() * water_offset
		var p2w = p2.normalized() * water_offset
		var p3w = p3.normalized() * water_offset
		
		# water depth
		var p1w_depth = p1.length_squared() - p1w.length_squared()
		var p2w_depth = p2.length_squared() - p2w.length_squared()
		var p3w_depth = p3.length_squared() - p3w.length_squared()
		
		# water color
		var depth_start = 0.001
		var depth_end = 0.05
		var p1w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-p1w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		var p2w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-p2w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		var p3w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-p3w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		
		# land triangles
		var pl = Plane(p1, p2, p3)
		var n = pl.normal
		
		_triangle(p1, p2, p3, arrays[0])
		_triangle(n,n,n, arrays[1])
		_tricolor(p1_color, p2_color, p3_color, arrays[2])
		
		# water triangles
		if (p1w_depth < 0.04 and p2w_depth < 0.04 and p3w_depth < 0.04):
			_triangle(p1w, p2w, p3w, arrays[3])
			_triangle(p1w.normalized(), p2w.normalized(), p3w.normalized(), arrays[4])
			_tricolor(p1w_color, p2w_color, p3w_color, arrays[5])
	else:
		recursion += 1
		var ang = p1.angle_to(p2)
		var ang2 = p2.angle_to(p3)
		var ang3 = p1.angle_to(p3)
		var ax: Vector3
		var newpoint: Vector3
		var n: Vector3
		
		if ang == 0.0 or ang2 == 0.0 or ang3 == 0.0:
			print('zero vector :(')
		else:
			ax = p1.cross(p2).normalized()
			newpoint = p1.rotated(ax, ang*0.5)
			var p12 = newpoint.snapped(Vector3(vsnap, vsnap, vsnap))
			
			ax = p2.cross(p3).normalized()
			newpoint = p2.rotated(ax, ang2*0.5)
			var p23 = newpoint.snapped(Vector3(vsnap, vsnap, vsnap))
			
			ax = p1.cross(p3).normalized()
			newpoint = p1.rotated(ax, ang3*0.5)
			var p31 = newpoint.snapped(Vector3(vsnap, vsnap, vsnap))
			
			for pt in used_vecs:
				if p12.distance_squared_to(pt) < max_distance_between_vecs:
					p12 = pt
					break
			for pt in used_vecs:
				if p23.distance_squared_to(pt) < max_distance_between_vecs:
					p23 = pt
					break
			for pt in used_vecs:
				if p31.distance_squared_to(pt) < max_distance_between_vecs:
					p31 = pt
					break
			for pt in used_border_vecs:
				if p31.distance_squared_to(pt) < max_distance_between_vecs:
					p31 = pt
					break
			if !used_border_vecs.has(p31):
				used_border_vecs.append(p31)
			
			if !used_vecs.has(p12):
				used_vecs.append(p12)
			if !used_vecs.has(p23):
				used_vecs.append(p23)
			if !used_vecs.has(p31):
				used_vecs.append(p31)
			
			_sub_triangle(p1, p12, p31, arrays, used_vecs, used_border_vecs, recursion)
			
			_sub_triangle(p12, p2, p23, arrays, used_vecs, used_border_vecs, recursion)
			
			_sub_triangle(p31, p23, p3, arrays, used_vecs, used_border_vecs, recursion)
			
			_sub_triangle(p12, p23, p31, arrays, used_vecs, used_border_vecs, recursion)

func draw_trimesh(arr: PackedVector3Array, normal_arr: PackedVector3Array, msh: ArrayMesh):
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	surface_array[Mesh.ARRAY_VERTEX] = arr
	surface_array[Mesh.ARRAY_NORMAL] = normal_arr
	
	msh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)

func NEW_tesselate(og_verts: PackedVector3Array, og_idx: int, ring_array: PackedVector3Array, thickness: float, used_border_vecs: PackedVector3Array,
		water = true):
	var wall_triangles = PackedVector3Array()
	var wall_tri_colors = PackedColorArray()
	var wall_tri_normals = PackedVector3Array()
	var cutwater_triangles = PackedVector3Array()
	var cutwater_tri_normals = PackedVector3Array()
	var cutwater_tri_colors = PackedColorArray()

	for b in len(ring_array)-1:
		var v0 = ring_array[b]
		var v1 = ring_array[b+1]
		for pt in used_border_vecs:
			if v0.distance_squared_to(pt) < max_distance_between_vecs:
				v0 = pt
			if v1.distance_squared_to(pt) < max_distance_between_vecs:
				v1 = pt
		if !used_border_vecs.has(v0):
			used_border_vecs.append(v0)
		if !used_border_vecs.has(v1):
			used_border_vecs.append(v1)
		var v0p = mm(v0*thickness)
		var v0pw = v0p.normalized()*water_offset
		var v0pw_depth = v0p.length_squared() - v0pw.length_squared()
		#edges_for_particles.append(v0p)
		var v1p = mm(v1*thickness)
		var v1pw = v1p.normalized()*water_offset
		var v1pw_depth = v1p.length_squared() - v1pw.length_squared()
		#edges_for_particles.append(v1p)
		
		var vp = mm(og_verts[og_idx]*thickness)
		var vpw = vp.normalized()*water_offset
		var vpw_depth = vp.length_squared() - vpw.length_squared()
		
		var depth_start = 0.001
		var depth_end = 0.05
		var v0pw_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v0pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		var v1pw_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		
		## PIECE WALLS BEGIN ## -----------------------------
		
		_triangle(v0, v0p, v1, wall_triangles)
		
		_tricolor(low_crust_color, crust_color, low_crust_color, wall_tri_colors)
		
		var n = Plane(v0, v0p, v1).normal
		_triangle(n, n, n, wall_tri_normals)
		
		###
		
		_triangle(v1, v0p, v1p, wall_triangles)
		
		_tricolor(low_crust_color, crust_color, crust_color, wall_tri_colors)
		
		n = Plane(v1, v0p, v1p).normal
		_triangle(n, n, n, wall_tri_normals)
		
		_triangle(v0p.limit_length(water_offset), v0pw.lerp(vp, 0.001), v1p.limit_length(water_offset), cutwater_triangles)
		
		var c1 = v0pw_color.lerp(Color('black'), clamp(remap(clamp(-v0pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		var c3 = v1pw_color.lerp(Color('black'), clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		_tricolor(c1, v0pw_color, c3, cutwater_tri_colors)
		
		n = Plane(v0p,v0pw,v1p).normal
		_triangle(n, n, n, cutwater_tri_normals)
		
		###
		
		_triangle(v1p.limit_length(water_offset), v0pw.lerp(vp, 0.001), v1pw.lerp(vp, 0.001), cutwater_triangles)
		
		c1 = v1pw_color.lerp(Color('black'), clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		_tricolor(c1, v0pw_color, v1pw_color, cutwater_tri_colors)
		
		n = Plane(v1p,v0pw,v1pw).normal
		_triangle(n, n, n, cutwater_tri_normals)
		
		## PIECE WALLS END ## -----------------------------
		
		## PIECE BOTTOM BEGIN ## -----------------------------
		
		_triangle(v1,og_verts[og_idx],v0,wall_triangles)

		_tricolor(low_crust_color,low_crust_color,low_crust_color,wall_tri_colors)

		n = Plane(v1,og_verts[og_idx],v0).normal
		_triangle(n,n,n,wall_tri_normals)
		
		## PIECE BOTTOM END ## -----------------------------
	
	return [wall_triangles, wall_tri_normals, wall_tri_colors,
		cutwater_triangles, cutwater_tri_normals, cutwater_tri_colors]

func tesselate(og_verts: PackedVector3Array, og_idx: int, ring_array: PackedVector3Array,
		thickness: float, water = true):
	var wall_triangles = PackedVector3Array()
	var wall_tri_colors = PackedColorArray()
	var wall_tri_normals = PackedVector3Array()
	var border_triangles = PackedVector3Array()
	var border_tri_normals = PackedVector3Array()
	var border_tri_colors = PackedColorArray()
	var water_triangles = PackedVector3Array()
	var water_tri_normals = PackedVector3Array()
	var water_tri_colors = PackedColorArray()
	var cutwater_triangles = PackedVector3Array()
	var cutwater_tri_normals = PackedVector3Array()
	var cutwater_tri_colors = PackedColorArray()
	
	var land_colors = [land_color, land_color_2, land_color_3]
	
	#     v0--1--v0p-5--v0p2---v0p3
	#     |     /|     /|     /|\
	#     |    / |    / |    / | \
	#     |   2  |   6  |   /  |  vp
	#     |  3   4  7   8  /   |  /
	#     | /    | /    | /    | /
	#     |/     |/     |/     |/
	#     v1-----v1p----v1p2---v1p3
	
	#     v0--1--v0p-5--v0p2
	#     |     /|     /|\     
	#     |    / |    / | \   
	#     |   2  |   6  |  \ v0p3
	#     |  3   4  7   8  /  | 
	#     | /    | /    | /   | 
	#     |/     |/     |/    | 
	#     v1-----v1p----v1p2  |
	#                       \ |
	#                        \|
	#                        ...
	
	#     v0--1--v0p-5--v0p2---v0p3
	#     |     /|     /|     / \
	#     |    / |    / |    /   \
	#     |   2  |   6  |   /     vp
	#     |  3   4  7   8  /    /
	#     | /    | /    | /    /
	#     |/     |/     |/    /
	#     v1-----v1p----v1p2
	
	for b in len(ring_array)-1:
		var v0 = ring_array[b]
		var v1 = ring_array[b+1]
		var v0p = mm(ring_array[b]*thickness)
		var v0pw = v0p.normalized()*water_offset
		var v0pw_depth = v0p.length_squared() - v0pw.length_squared()
		#edges_for_particles.append(v0p)
		var v1p = mm(ring_array[b+1]*thickness)
		var v1pw = v1p.normalized()*water_offset
		var v1pw_depth = v1p.length_squared() - v1pw.length_squared()
		#edges_for_particles.append(v1p)
		
		var vp = mm(og_verts[og_idx]*thickness)
		var vpw = vp.normalized()*water_offset
		var vpw_depth = vp.length_squared() - vpw.length_squared()
		
		var v0p_color = land_colors[color_vary(v0p)].lerp(low_land_color, clamp(remap(v0p.length_squared(), low_land_bottom_threshold, pow(max_terrain_height, 2.0), 1.0, 0.0), 0.0, 1.0))
		var v1p_color = land_colors[color_vary(v1p)].lerp(low_land_color, clamp(remap(v1p.length_squared(), low_land_bottom_threshold, pow(max_terrain_height, 2.0), 1.0, 0.0), 0.0, 1.0))
		var depth_start = 0.001
		var depth_end = 0.05
		var v0pw_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v0pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		var v1pw_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		
		if v0p.length() < sand_threshold and ocean:
			v0p_color = sand_color
		elif asin(abs(v0p.normalized().y)) > snow_start and snow:
			v0p_color = land_snow_color
		if v1p.length() < sand_threshold and ocean:
			v1p_color = sand_color
		elif asin(abs(v1p.normalized().y)) > snow_start and snow:
			v1p_color = land_snow_color
		
		## PIECE WALLS BEGIN ## -----------------------------
		
		_triangle(v0, v0p, v1, wall_triangles)
		
		_tricolor(low_crust_color, crust_color, low_crust_color, wall_tri_colors)
		
		var n = Plane(v0, v0p, v1).normal
		_triangle(n, n, n, wall_tri_normals)
		
		###
		
		_triangle(v1, v0p, v1p, wall_triangles)
		
		_tricolor(low_crust_color, crust_color, crust_color, wall_tri_colors)
		
		n = Plane(v1, v0p, v1p).normal
		_triangle(n, n, n, wall_tri_normals)
		
		_triangle(v0p.limit_length(water_offset), v0pw.lerp(vp, 0.001), v1p.limit_length(water_offset), cutwater_triangles)
		
		var c1 = v0pw_color.lerp(Color('black'), clamp(remap(clamp(-v0pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		var c3 = v1pw_color.lerp(Color('black'), clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		_tricolor(c1, v0pw_color, c3, cutwater_tri_colors)
		
		n = Plane(v0p,v0pw,v1p).normal
		_triangle(n, n, n, cutwater_tri_normals)
		
		###
		
		_triangle(v1p.limit_length(water_offset), v0pw.lerp(vp, 0.001), v1pw.lerp(vp, 0.001), cutwater_triangles)
		
		c1 = v1pw_color.lerp(Color('black'), clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		_tricolor(c1, v0pw_color, v1pw_color, cutwater_tri_colors)
		
		n = Plane(v1p,v0pw,v1pw).normal
		_triangle(n, n, n, cutwater_tri_normals)
		
		## PIECE WALLS END ## -----------------------------
		
		var v0p2 = mm(v0p.move_toward(vp, v0p.distance_to(vp)/3).normalized()*thickness)
		var v0p2w = v0p2.normalized()*water_offset
		var v0p2w_depth = v0p2.length_squared() - v0p2w.length_squared()
		var v1p2 = mm(v1p.move_toward(vp, v1p.distance_to(vp)/3).normalized()*thickness)
		var v1p2w = v1p2.normalized()*water_offset
		var v1p2w_depth = v1p2.length_squared() - v1p2w.length_squared()
		
		var v0p2_color = land_colors[color_vary(v0p2)].lerp(low_land_color, clamp(remap(v0p2.length_squared(), low_land_bottom_threshold, pow(max_terrain_height, 2.0), 1.0, 0.0), 0.0, 1.0))
		var v1p2_color = land_colors[color_vary(v1p2)].lerp(low_land_color, clamp(remap(v1p2.length_squared(), low_land_bottom_threshold, pow(max_terrain_height, 2.0), 1.0, 0.0), 0.0, 1.0))
		
		if v0p2.length() < sand_threshold and ocean:
			v0p2_color = sand_color
		elif asin(abs(v0p2.normalized().y)) > snow_start and snow:
			v0p2_color = land_snow_color
		if v1p2.length() < sand_threshold and ocean:
			v1p2_color = sand_color
		elif asin(abs(v1p2.normalized().y)) > snow_start and snow:
			v1p2_color = land_snow_color
		
		var v0p2w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v0p2w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		var v1p2w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v1p2w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		
		## PIECE TOP BEGIN ## -----------------------------
		
		_triangle(v0p,v0p2,v1p,border_triangles)
		
		_tricolor(v0p_color,v0p2_color,v1p_color,border_tri_colors)
		
		n = Plane(v0p,v0p2,v1p).normal
		_triangle(n,n,n,border_tri_normals)
		
		_triangle(v0pw, v0p2w, v1pw, water_triangles)
		
		_tricolor(v0pw_color, v0p2w_color, v1pw_color, water_tri_colors)
		
		n = Plane(v0pw,v0p2w,v1pw).normal
		_triangle(v0pw.normalized(), v0p2w.normalized(), v1pw.normalized(), water_tri_normals)
		
		###
		
		_triangle(v1p,v0p2,v1p2,border_triangles)
		
		_tricolor(v1p_color,v0p2_color,v1p2_color,border_tri_colors)
		
		n = Plane(v1p,v0p2,v1p2).normal
		_triangle(n,n,n,border_tri_normals)
		
		_triangle(v1pw, v0p2w, v1p2w, water_triangles)
		
		_tricolor(v1pw_color, v0p2w_color, v1p2w_color, water_tri_colors)
		
		n = Plane(v1pw,v0p2w,v1p2w).normal
		_triangle(v1pw.normalized(), v0p2w.normalized(), v1p2w.normalized(), water_tri_normals)
		
		#3
		
		var v0p3 = mm(v0p2.move_toward(vp, v0p2.distance_to(vp)/3).normalized()*thickness)
		var v0p3w = v0p3.normalized()*water_offset
		var v0p3w_depth = v0p3.length_squared() - v0p3w.length_squared()
		var v1p3 = mm(v1p2.move_toward(vp, v1p2.distance_to(vp)/3).normalized()*thickness)
		var v1p3w = v1p3.normalized()*water_offset
		var v1p3w_depth = v1p3.length_squared() - v1p3w.length_squared()
		
		var v0p3_color = land_colors[color_vary(v0p3)].lerp(low_land_color, clamp(remap(v0p3.length_squared(), low_land_bottom_threshold, pow(max_terrain_height, 2.0), 1.0, 0.0), 0.0, 1.0))
		var v1p3_color = land_colors[color_vary(v1p3)].lerp(low_land_color, clamp(remap(v1p3.length_squared(), low_land_bottom_threshold, pow(max_terrain_height, 2.0), 1.0, 0.0), 0.0, 1.0))
		
		if v0p3.length() < sand_threshold and ocean:
			v0p3_color = sand_color
		elif asin(abs(v0p3.normalized().y)) > snow_start and snow:
			v0p3_color = land_snow_color
		if v1p3.length() < sand_threshold and ocean:
			v1p3_color = sand_color
		elif asin(abs(v1p3.normalized().y)) > snow_start and snow:
			v1p3_color = land_snow_color
		
		var v0p3w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v0p3w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		var v1p3w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v1p3w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		
		###
		
		_triangle(v0p2,v0p3,v1p2,border_triangles)
		
		_tricolor(v0p2_color,v0p3_color,v1p2_color,border_tri_colors)
		
		n = Plane(v0p2,v0p3,v1p2).normal
		_triangle(n,n,n,border_tri_normals)
		
		_triangle(v0p2w, v0p3w, v1p2w, water_triangles)
		
		_tricolor(v0p2w_color, v0p3w_color, v1p2w_color, water_tri_colors)

		n = Plane(v0p2w,v0p3w,v1p2w).normal
		_triangle(v0p2w.normalized(), v0p3w.normalized(), v1p2w.normalized(), water_tri_normals)
		
		###
		
		_triangle(v1p2,v0p3,v1p3,border_triangles)

		_tricolor(v1p2_color,v0p3_color,v1p3_color,border_tri_colors)

		n = Plane(v1p2,v0p3,v1p3).normal
		_triangle(n,n,n,border_tri_normals)
		
		_triangle(v1p2w, v0p3w, v1p3w, water_triangles)
		
		_tricolor(v1p2w_color, v0p3w_color, v1p3w_color, water_tri_colors)

		n = Plane(v1p2w,v0p3w,v1p3w).normal
		_triangle(v1p2w.normalized(), v0p3w.normalized(), v1p3w.normalized(), water_tri_normals)
		
		#vp
		
		var vp_color = land_colors[color_vary(vp)].lerp(low_land_color, clamp(remap(vp.length_squared(), low_land_bottom_threshold, pow(max_terrain_height, 2.0), 1.0, 0.0), 0.0, 1.0))
		var vpw_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-vpw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		
		if vp.length() < sand_threshold and ocean:
			vp_color = sand_color
		elif asin(abs(vp.normalized().y)) > snow_start and snow:
			vp_color = land_snow_color
		
		###
		
		_triangle(v0p3,vp,v1p3,border_triangles)
		
		_tricolor(v0p3_color,vp_color,v1p3_color,border_tri_colors)
		
		n = Plane(v0p3,vp,v1p3).normal
		_triangle(n,n,n,border_tri_normals)
		
		_triangle(v0p3w, vpw, v1p3w, water_triangles)
		
		_tricolor(v0p3w_color, vpw_color, v1p3w_color, water_tri_colors)

		n = Plane(v0p3w,vpw,v1p3w).normal
		_triangle(v0p3w.normalized(), vpw.normalized(), v1p3w.normalized(), water_tri_normals)
		
		## PIECE TOP END ## -----------------------------
		
		## PIECE BOTTOM BEGIN ## -----------------------------
		
		_triangle(v1,og_verts[og_idx],v0,border_triangles)
		
		_tricolor(low_crust_color,low_crust_color,low_crust_color,border_tri_colors)
		
		n = Plane(v0,og_verts[og_idx],v1).normal
		_triangle(n,n,n,border_tri_normals)
		
		## PIECE BOTTOM END ## -----------------------------
	
	return [wall_triangles, wall_tri_normals, wall_tri_colors,
		border_triangles, border_tri_normals, border_tri_colors,
		water_triangles, water_tri_normals, water_tri_colors,
		cutwater_triangles, cutwater_tri_normals, cutwater_tri_colors]
		
func _triangle(p1: Vector3, p2: Vector3, p3: Vector3, arr: PackedVector3Array):
	arr.append(p1)
	arr.append(p2)
	arr.append(p3)

func _tricolor(p1: Color, p2: Color, p3: Color, arr: PackedColorArray):
	arr.append(p1)
	arr.append(p2)
	arr.append(p3)

func NEW_verts_to_dpoints(og_verts: PackedVector3Array, dtc: Dictionary):
	var result = {}
	var l = len(og_verts)
	for v in l:
		result[v] = PackedVector3Array()
		for dtc_k in dtc.keys():
			if og_verts[v] in dtc_k:
				if !result[v].has(dtc[dtc_k]):
					result[v].append(dtc[dtc_k])
	return result

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
			border_array.append(border_vecs[i])
		border_array.append(border_vecs[0])
		result[v] = border_array
	return result

func NEW_fill_border_halfways(vbdict: Dictionary, og_verts: PackedVector3Array, used_border_vecs: PackedVector3Array):
	for vi in vbdict.keys():
		var border_array = vbdict[vi]
		var new_border_array = PackedVector3Array()
		for b in len(border_array):
			var plus1 = b+1

			if plus1 == len(border_array):
				## last one
				plus1 = 0
				var current_border_point = border_array[b].snapped(Vector3(0.001, 0.001, 0.001))
				var next_border_point = border_array[plus1].snapped(Vector3(0.001, 0.001, 0.001))
				for pt in used_border_vecs:
					if current_border_point.distance_squared_to(pt) < max_distance_between_vecs:
						current_border_point = pt
						break
				for pt in used_border_vecs:
					if next_border_point.distance_squared_to(pt) < max_distance_between_vecs:
						next_border_point = pt
						break
				if current_border_point != next_border_point:
					var ang = current_border_point.angle_to(next_border_point)
					var ax = current_border_point.cross(next_border_point).normalized()
					#if !(new_border_array.has(current_border_point)):
					new_border_array.append(current_border_point)
					var halfway = current_border_point.rotated(ax, ang/2.0).snapped(Vector3(0.001, 0.001, 0.001))
					for pt in used_border_vecs:
						if halfway.distance_squared_to(pt) < max_distance_between_vecs:
							halfway = pt
							break
					#if !(new_border_array.has(halfway)):
					new_border_array.append(halfway)
					#if !(new_border_array.has(next_border_point)):
					new_border_array.append(next_border_point)
					if !used_border_vecs.has(current_border_point):
						used_border_vecs.append(current_border_point)
					if !used_border_vecs.has(halfway):
						used_border_vecs.append(halfway)
					if !used_border_vecs.has(next_border_point):
						used_border_vecs.append(next_border_point)
			else:
				var current_border_point = border_array[b].snapped(Vector3(0.001, 0.001, 0.001))
				var next_border_point = border_array[plus1].snapped(Vector3(0.001, 0.001, 0.001))
				for pt in used_border_vecs:
					if current_border_point.distance_squared_to(pt) < max_distance_between_vecs:
						current_border_point = pt
						break
				for pt in used_border_vecs:
					if next_border_point.distance_squared_to(pt) < max_distance_between_vecs:
						next_border_point = pt
						break
				if current_border_point != next_border_point:
					var ang = current_border_point.angle_to(next_border_point)
					var ax = current_border_point.cross(next_border_point).normalized()
					if !(new_border_array.has(current_border_point)):
						new_border_array.append(current_border_point)
					var halfway = current_border_point.rotated(ax, ang/2.0).snapped(Vector3(0.001, 0.001, 0.001))
					for pt in used_border_vecs:
						if halfway.distance_squared_to(pt) < max_distance_between_vecs:
							halfway = pt
							break
					if !(new_border_array.has(halfway)):
						new_border_array.append(halfway)
					if !(new_border_array.has(next_border_point)):
						new_border_array.append(next_border_point)
					
					if !used_border_vecs.has(current_border_point):
						used_border_vecs.append(current_border_point)
					if !used_border_vecs.has(halfway):
						used_border_vecs.append(halfway)
					if !used_border_vecs.has(next_border_point):
						used_border_vecs.append(next_border_point)
		vbdict[vi] = new_border_array
	return vbdict

func fill_border_halfways(vbdict: Dictionary, og_verts: PackedVector3Array):
	for vi in vbdict.keys():
		var border_array = vbdict[vi]
		var new_border_array = PackedVector3Array()
		for b in len(border_array):
			var plus1 = b+1
			if plus1 == len(border_array):
				## last one
				pass
			else:
				var current_border_point = border_array[b]
				var next_border_point = border_array[plus1]
				
				var bb_dist = current_border_point.distance_to(next_border_point)
				new_border_array.append(current_border_point)
				if bb_dist > vertex_fill_threshold:
					var halfway = current_border_point.move_toward(next_border_point, bb_dist/2.0).normalized()
					new_border_array.append(halfway)
				new_border_array.append(next_border_point)
		vbdict[vi] = new_border_array
	return vbdict

func NEW_delaunay(points: PackedVector3Array, return_tris := false):
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
				var plarr = PackedVector3Array([points[p], points[p2], points[p3]])
				var plarr2 = PackedVector3Array([points[p], points[p3], points[p2]])
				
				if is_good:
					for c in len(centers):
						if centers[c].angle_to(plc) < vertex_merge_threshold:
							plc = centers[c]
							break
					if !return_tris:
						#_sub_triangle(points[p], points[p2], points[p3], triangles, triangle_normals)
						_triangle(points[p], points[p2], points[p3], triangles)
						var n = Plane(points[p], points[p2], points[p3]).normal
						_triangle(n, n, n, triangle_normals)
#						var off = plc*0.0
#						surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array([points[p]+off,points[p2]+off,points[p3]+off])
#						newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
					else:
						if !centers.has(plc):
							centers.append(plc)
						good_triangles.append([p,p2,p3])
						if !tris.has(plarr) and !tris.has(plarr2):
							tris[plarr] = plc
				if is_good2:
					for c in len(centers):
						if centers[c].angle_to(plc) < vertex_merge_threshold:
							plc = centers[c]
							break
					if !return_tris:
						#_sub_triangle(points[p], points[p3], points[p2], triangles, triangle_normals)
						_triangle(points[p], points[p3], points[p2], triangles)
						var n = Plane(points[p], points[p3], points[p2]).normal
						_triangle(n, n, n, triangle_normals)
#						var off = plc*0.0
#						surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array([points[p]+off,points[p3]+off,points[p2]+off])
#						newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
					else:
						if !centers.has(plc):
							centers.append(plc)
						good_triangles.append([p,p3,p2])
						if !tris.has(plarr2) and !tris.has(plarr):
							tris[plarr2] = plc
						
#	print(len(centers))
#	print(len(tris))
	return tris

func delaunay(points: PackedVector3Array, return_tris = false):
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
				var plc = pl.get_center()
				var pl2c = pl2.get_center()

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
				if is_good:
					good_triangles.append([p,p2,p3])
					if !return_tris:
						var off = plc.normalized()*0.0
						surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array([points[p]+off,points[p2]+off,points[p3]+off])
					else:
						var plarr = PackedVector3Array([points[p], points[p2], points[p3]])
						tris[plarr] = plc.normalized()
						centers.append(plc.normalized())
				if is_good2:
					good_triangles.append([p,p3,p2])
					if !return_tris:
						var off = plc.normalized()*0.0
						surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array([points[p]+off,points[p3]+off,points[p2]+off])
					else:
						var plarr = PackedVector3Array([points[p], points[p3], points[p2]])
						tris[plarr] = pl2c.normalized()
						centers.append(pl2c.normalized())
	#print(len(good_triangles))
	#print(float(good_triangles)/float(num_of_points))
	if return_tris:
		return tris

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

func mm(vec: Vector3):
	var offset = noise3d.get_noise_3dv(vec)
	#print(offset)
	if invert_height:
		offset = 1.0 - offset
#	if ocean:
#		offset = clamp(remap(offset, -1.0, 1.0, 0.9, max_terrain_height_unclamped), 0.97, max_terrain_height)
#	else:
	var newvec = vec * remap(offset, -1.0, 1.0, min_terrain_height_unclamped, max_terrain_height_unclamped)
	if clamp_terrain:
		newvec = newvec.limit_length(max_terrain_height)
		if newvec.length_squared() < pow(min_terrain_height, 2.0):
			newvec = newvec.normalized() * min_terrain_height
	if craters:
		var my_craters = []
		for cr in crater_array:
			var dist = vec.normalized().distance_squared_to(cr[0])
			if dist <= cr[1] * 0.01:
				var dist_mapped = remap(dist, 0.0, cr[1] * 0.01, 0.0, 1.0)
				my_craters.append(dist_mapped)
		for mycr_i in len(my_craters):
			newvec *= 1.0 + (crater_height_curve.sample(my_craters[mycr_i]) * 0.02 * ((mycr_i + 1) / len(my_craters)))
#		if newvec.length_squared() > pow(crater_height_threshold, 2.0):
#			newvec *= 1 + (pow(crater_height_threshold, 2.0) - newvec.length_squared())
	return newvec

func color_vary(vec: Vector3):
	var nval = remap(colornoise.get_noise_3dv(vec), -1.0, 1.0, 0.0, 2.0)
	#var nval = vec.length_squared()
	#print(nval)
	if nval >= pow(land_color_threshold, 2.0) + randi_range(-0.05, 0.05):
		return 0
	elif nval <= pow(land_color_threshold_2, 2.0) + randi_range(-0.05, 0.05):
		return 2
	else:
		return 1
	
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
