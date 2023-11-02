extends Node3D

@export var debug := false
@export var max_points = 30
@export var generations = 100
@export var save: bool = false
@export_enum('load', 'generate') var mesh_source: int = 1
@export var mesh_resource: Resource
@export var pieces_at_start: int = 15
@export var piece_offset := 1.0
@export_category('Terrain')
@export var crust_thickness := 1.1
@export var vertex_merge_threshold := 0.168
@export_range(1.0, 5.0, 2.0) var sub_triangle_recursion := 3
@export_enum('custom', 'mercury', 'venus', 'earth', 'moon', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune', 'pluto') var planet_style := 3

var piece_place_lerp_curve: Curve
var ocean := true
var snow := true
var snow_random_low := 0.85
var snow_random_high := 0.95
var min_terrain_height_unclamped := 0.9
var max_terrain_height_unclamped := 1.1
var craters := false
var crater_size_multiplier := 1.0
var crater_height_multiplier := 1.0
var num_craters := 10
var crater_height_curve: Curve
var h_bands := false
var h_band_snap := 0.01
var h_band_wiggle := 0.1
var craters_to_storms := false
var storm_flatness := 4.0
var craters_to_mountains := false
var mountain_shift_curve: Curve

var manual_storm_color := false
var storm_color: Color
var storm_color_curve: Curve
var mountain_color: Color
var mountain_color_curve: Curve
var color_test := Color('Black')
var low_crust_color := Color('3f3227')
var crust_color := Color('3f3227')
var land_snow_color := Color('dbdbdb')
var land_color_ease_curve: Curve
var land_color := Color('4a6c3f')
var land_color_2 := Color('4d6032')
var land_color_3 := Color('5e724c')
var tint_color := Color('69808a')
var tint_color_2 := Color('69808a')
var tint_color_3 := Color('69808a')
var low_land_color := Color('74432e')
var low_land_bottom_threshold := 0.95
var low_land_top_threshold := 1.1
var sand_color := Color('9f876b')
var water_color := Color('0541ff')
var shallow_water_color := Color('2091bf')
var sand_threshold := 1.1
var water_offset := 1.09
var color_noise_frequency: float = 1.5
var color_noise_type: FastNoiseLite.NoiseType
var color_noise_domain_warp := false
var color_domain_warp_amplitude := 30.0
var color_domain_warp_fractal_gain := 0.5
var color_domain_warp_fractal_lacunarity := 6.0
var color_domain_warp_fractal_octaves := 5
var color_domain_warp_fractal_type: FastNoiseLite.DomainWarpFractalType = 1
var color_domain_warp_frequency := 0.05
var color_domain_warp_type: FastNoiseLite.DomainWarpType = 0
var color_fractal_gain := 0.5
var color_fractal_lacunarity := 2.0
var color_fractal_octaves := 5
var color_fractal_ping_pong_strength := 2.0
var color_fractal_type: FastNoiseLite.FractalType = 1
var color_fractal_weighted_strength := 0.0

var piece = preload("res://scenes/planet_piece.tscn")
var save_template = preload("res://scripts/save_template.gd")
var mantle_earth_material = preload("res://tex/mantle_earth_material.tres")
var mantle_mars_material = preload("res://tex/mantle_mars_material.tres")
var mantle_moon_material = preload("res://tex/mantle_moon_material.tres")
var mantle_earth_2_material = preload("res://tex/mantle_earth_2_material.tres")
var mantle_mars_2_material = preload("res://tex/mantle_mars_2_material.tres")
var moon_crater_curve = preload("res://tex/moon_crater_curve.tres")
var moon_land_curve = preload("res://tex/moon_land_color_curve.tres")
var jupiter_storm_curve = preload("res://tex/jupiter_storm_curve.tres")
var mantle_jupiter_material = preload("res://tex/mantle_jupiter_material.tres")
var mantle_saturn_material = preload("res://tex/mantle_saturn_material.tres")
var mantle_uranus_material = preload("res://tex/mantle_uranus_material.tres")
var neptune_storm_curve = preload("res://tex/neptune_storm_curve.tres")
var neptune_storm_color_curve = preload("res://tex/neptune_storm_color_curve.tres")
var earth_mountain_curve = preload("res://tex/earth_mountain_curve.tres")
var earth_mountain_shift_curve = preload("res://tex/earth_mountain_shift_curve.tres")
var earth_mountain_color_curve = preload("res://tex/earth_mountain_color_curve.tres")
var mercury_crater_curve = preload("res://tex/mercury_crater_curve.tres")
var mercury_land_color_curve = preload("res://tex/mercury_land_color_curve.tres")
var mars_mountain_curve: Curve = preload("res://tex/mars_mountain_curve.tres")
var venus_color_ease_curve: Curve = preload("res://tex/venus_color_ease_curve.tres")
var pluto_color_ease_curve: Curve = preload("res://tex/pluto_color_ease_curve.tres")
var mars_color_ease_curve: Curve = preload("res://tex/mars_land_color_curve.tres")
var earth_color_ease_curve: Curve = preload("res://tex/earth_land_color_curve.tres")

var _draw_mode := false
var manual_mountain_color := false

var lava_lamp_color_earth = Color('f1572f')
var lava_lamp_color_mars = Color('c08333')
var lava_lamp_color_jupiter = Color('64788f')
var lava_lamp_color_saturn = Color('8b79b3')
var lava_lamp_color_uranus = Color('92a2ab')

var noise3d = FastNoiseLite.new()
var colornoise = FastNoiseLite.new()
var colornoise2 = FastNoiseLite.new()
var mountain_noise = FastNoiseLite.new()
var general_noise_soft = FastNoiseLite.new()
var saver = ResourceSaver
var loader = ResourceLoader
var load_failed: bool = false
var looking: bool = false
var current_piece: Node3D
var current_piece_mesh: MeshInstance3D
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
var deep_water_color: Color
var water_color_2: Color
var water_color_3: Color


var treesnap: Vector3
var treestep := 0.2
var vsnap := 0.00005

var correct_rotation := false

var rotowindow

var thread: Thread

var build_planet := false
var parameters_set := false
var ufo_locations := {}

var piece_place_lerp_progression := 0.0
var piece_place_vibration := false
var piece_place_lerp_brick_audio_one := preload("res://tex/brick_audio_one_lerp_curve.tres")

var pluto_heart_center: Vector3
var pluto_heart_plane: Plane
var pluto_heart_yax: Vector3
var pluto_heart_xax: Vector3
var pluto_heart_color := Color('d5b39a')

var canyon_noise: FastNoiseLite = preload("res://tex/canyon_noise.tres")
var canyons := false
var num_canyons := 0
var canyon_array := []
var canyon_size_multiplier := 17.0
var canyon_height_multiplier := 1.0
var canyon_height_curve: Curve = preload("res://tex/canyon_height_curve.tres")
var canyon_fade_curve: Curve = preload("res://tex/canyon_fade_curve.tres")

var turb1 := 0.2
var turb2 := 0.2

var jupiter_turbulence := 0.05
var saturn_turbulence := 0.05
var uranus_turbulence := 0.05
var neptune_turbulence := 0.05

var tree_noise := preload("res://tex/tree_noise.tres")
var gas_color_ease_curve: Curve
var jupiter_color_ease_curve := preload("res://tex/jupiter_color_ease_curve.tres")
var saturn_color_ease_curve := preload("res://tex/saturn_color_ease_curve.tres")
var uranus_color_ease_curve := preload("res://tex/uranus_color_ease_curve.tres")
var neptune_color_ease_curve := preload("res://tex/neptune_color_ease_curve.tres")

@onready var rings = $"../Rings"
@onready var lava_lamp = $"../Lava Lamp"
@onready var piece_target = $"../h/v/Camera3D/piece_target"
@onready var shadow_light = $"../h/v/Camera3D/ShadowLight"
@onready var camera_3d = $"../h/v/Camera3D"
@onready var sun = $"../Sun"
@onready var space = $"../Space"
@onready var mantle = $"../Mantle"
@onready var pieces = $"../Pieces"

# Called when the node enters the scene tree for the first time.
func _ready():
	piece_place_lerp_curve = piece_place_lerp_brick_audio_one
	treesnap = Vector3(treestep, treestep, treestep)
	global = get_node('/root/Global')
	global.wheel_rot_signal.connect(_on_global_wheel_rot_signal)
	global.loaded_pieces_ready.connect(_on_global_loaded_pieces_ready)
	rotowindow = get_tree().root.get_node('UX/RotoWindow')
	if !(planet_style == 0) and !debug:
		planet_style = global.generate_type
		pieces_at_start = global.pieces_at_start
	randomize()
	canyon_noise.seed = randi_range(0, 100000)
	mountain_noise.seed = randi_range(0, 100000)
	general_noise_soft.seed = randi_range(0, 100000)
	colornoise.seed = randi_range(0, 100000)
	colornoise2.seed = randi_range(0, 100000)
	noise3d.seed = randi_range(0, 100000)
	noise3d.seed = randi_range(0, 100000)
	tree_noise.seed = randi_range(0, 100000)
	
	_set_parameters()
	thread = Thread.new()
	if global.title_screen:
		_load_title_planet()

func _process(delta):
	var result = false
	if build_planet:
		if !thread.is_alive() and !thread.is_started():
			thread.start(Callable(self, "_generate_mesh"))
		if !thread.is_alive() and thread.is_started():
			result = thread.wait_to_finish()
		if result:
			build_planet = false
			global.ufo_locations = ufo_locations
			global.ready_to_start = true
	else:
		if looking:
			_piece_fit(delta)
		if fit_timer > 1.5:
			_place_piece()
		if fit:
			if !placed_signal:
				current_piece.remove_from_group('pieces')
				global.pieces_placed_so_far[0] += 1
				print(global.pieces_placed_so_far)
				global._save_puzzle_status()
				placed_signal = true
				#placed_counting = true
				fit = false
#		if placed_counting:
#			placed_timer += delta
#			if placed_timer > 0.2:
#				global.placed_cidx = current_piece.circle_idx
#				placed_signal = false
#				placed_counting = false
#				placed_timer = 0.0

### DONE ###
func _place_piece():
	current_piece.reparent(pieces, false)
	current_piece.position = Vector3.ZERO
	current_piece.rotation = Vector3.ZERO
	current_piece_mesh.rotation = Vector3.ZERO
	current_piece.global_position = piece_target.global_position
	current_piece.placed = true
	fit = true
	looking = false
	fit_timer = 0.0
	shadow_light._on = false
	sun._on = true
	space._on = false
	rotowindow.visible = false

func _generate_mesh(userdata = null):
	var verts := PackedVector3Array()
	var vi_to_borders := Dictionary()
	
	if mesh_source == 1:
		### MAKE PUZZLE PIECE LOCATIONS ###
		while len(verts) < max_points:
			verts = array_of_points(verts)
			verts = shift_points(verts,0,1)
		for x in generations:
			verts = shift_points(verts,0,1)
		
		### CHECK FOR POINTS TOO CLOSE TO POLES ###
		for v in len(verts):
			if verts[v].angle_to(Vector3.UP) < PI/32:
				var x = Vector3.UP.cross(verts[v]).normalized()
				verts[v] = verts[v].rotated(x, PI/32)
			if verts[v].angle_to(Vector3.DOWN) < PI/32:
				var x = Vector3.DOWN.cross(verts[v]).normalized()
				verts[v] = verts[v].rotated(x, PI/32)
		
		var delaunay_triangle_centers: Dictionary
		delaunay_triangle_centers = delaunay(verts, true)
		var my_delaunay_points = verts_to_delaunay_points(verts, delaunay_triangle_centers)
		vi_to_borders = make_border_array(verts, my_delaunay_points)
		
		if snow_random_high > snow_random_low:
			snow_start = randf_range(snow_random_low, snow_random_high)
		elif snow_random_high == snow_random_low:
			snow_start = snow_random_high
		else:
			snow_start = 0.9
		
		craterize()
		canyonize()
		
		if planet_style == 10:
			pluto_heart_center = Vector3(randfn(0.0, 1.0),
										randfn(-0.1, 0.2),
										randfn(0.0, 1.0)).normalized()
			pluto_heart_plane = Plane(pluto_heart_center, pluto_heart_center)
			pluto_heart_yax = (pluto_heart_plane.project(Vector3(pluto_heart_center.x,
															pluto_heart_center.y + 1.0,
															pluto_heart_center.z)) - pluto_heart_center).normalized()
			pluto_heart_xax = -pluto_heart_yax.cross(pluto_heart_center)
		
		var vectree = {}
		_generate_terrain(vi_to_borders, verts, vectree)
	return true

func _set_parameters():
	if planet_style == 0:
		pass
	elif planet_style == 1:
		# mercury
		colornoise.noise_type = 4
		colornoise.frequency = 1.0
		colornoise.domain_warp_enabled = false
		colornoise.fractal_gain = 0.5
		colornoise.fractal_lacunarity = 2
		colornoise.fractal_octaves = 5
		colornoise.fractal_ping_pong_strength = 2
		colornoise.fractal_type = 1
		colornoise.fractal_weighted_strength = 0.735
		colornoise2.noise_type = 4
		colornoise2.frequency = 5.0
		colornoise2.domain_warp_enabled = false
		colornoise2.fractal_gain = 0.5
		colornoise2.fractal_lacunarity = 2
		colornoise2.fractal_octaves = 5
		colornoise2.fractal_ping_pong_strength = 2
		colornoise2.fractal_type = 1
		colornoise2.fractal_weighted_strength = 0.735
		noise3d.noise_type = 4
		noise3d.frequency = 2.731
		noise3d.domain_warp_enabled = false
		noise3d.fractal_gain = 0.5
		noise3d.fractal_lacunarity = 2.0
		noise3d.fractal_octaves = 5
		noise3d.fractal_ping_pong_strength = 2.0
		noise3d.fractal_type = 1
		noise3d.fractal_weighted_strength = 0.0
		low_crust_color = Color('452e27')
		crust_color = Color('2a2a2a')
		land_snow_color = Color('dbdbdb')
		land_color = Color('252525')
		land_color_2 = Color('6a6a6a')
		land_color_3 = Color('464646')
		tint_color = Color('523c54')
		tint_color_2 = Color('5e3a37')
		tint_color_3 = Color('4e4428')
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
		global.planet_height_for_ufo = 0.0
		min_terrain_height_unclamped = 0.882
		snow = false
		craters = true
		num_craters = 70
		crater_size_multiplier = 1.2
		crater_height_multiplier = 1.5
		crater_height_curve = mercury_crater_curve
		land_color_ease_curve = mercury_land_color_curve
		mantle.mesh.material = mantle_moon_material
		#lava_lamp.light_color = lava_lamp_color_earth
		lava_lamp.visible = false
		h_bands = false
		craters_to_storms = false
		rings.visible = false
	elif planet_style == 2:
		## venus
		mountain_noise.noise_type = 4
		mountain_noise.frequency = 5.0
		mountain_noise.fractal_weighted_strength = 0
		general_noise_soft.noise_type = 4
		general_noise_soft.frequency = 0.1
		general_noise_soft.fractal_weighted_strength = 1
		colornoise.noise_type = 4
		colornoise.frequency = 2.0
		colornoise.domain_warp_enabled = false
		colornoise.fractal_gain = 0.5
		colornoise.fractal_lacunarity = 2
		colornoise.fractal_octaves = 5
		colornoise.fractal_ping_pong_strength = 2
		colornoise.fractal_type = 1
		colornoise.fractal_weighted_strength = 0
		noise3d.noise_type = 4
		noise3d.frequency = 1.5
		noise3d.domain_warp_enabled = false
		noise3d.fractal_gain = 0.5
		noise3d.fractal_lacunarity = 2.0
		noise3d.fractal_octaves = 5
		noise3d.fractal_ping_pong_strength = 2.0
		noise3d.fractal_type = 1
		noise3d.fractal_weighted_strength = 0.0
		low_crust_color = Color('6e2e0c')
		crust_color = Color('3f3227')
		land_snow_color = Color('dbdbdb')
		land_color = Color('ac5c22')
		land_color_2 = Color('7e4e24')
		land_color_3 = Color('b35639')
		low_land_color = Color('5b2716')
		low_land_bottom_threshold = 0.5
		low_land_top_threshold = 0.9
		sand_color = Color('9f876b')
		water_color = Color('b59e87')
		water_color_2 = Color('8f6f59')
		water_color_3 = Color('c2aca0')
		deep_water_color = Color('853403')
		shallow_water_color = Color('b59e87')
		sand_threshold = 1.1
		water_offset = 1.2
		ocean = true
		snow_random_low = 0.7
		snow_random_high = 0.8
		max_terrain_height_unclamped = 1.2
		global.planet_height_for_ufo = 0.0
		min_terrain_height_unclamped = 0.75
		craters = true
		craters_to_mountains = true
		crater_height_curve = earth_mountain_curve
		mountain_shift_curve = earth_mountain_shift_curve
		mountain_color_curve = earth_mountain_color_curve
		land_color_ease_curve = venus_color_ease_curve
		mountain_color = Color('ab8773')
		manual_mountain_color = true
		num_craters = 20
		crater_size_multiplier = 2.0
		crater_height_multiplier = 0.7
		snow = false
		mantle.mesh.material = mantle_earth_2_material
		lava_lamp.light_color = lava_lamp_color_earth
		lava_lamp.visible = true
		h_bands = false
		craters_to_storms = false
		rings.visible = false
	elif planet_style == 3:
		## earth
		mountain_noise.noise_type = 4
		mountain_noise.frequency = 5.0
		mountain_noise.fractal_weighted_strength = 0
		general_noise_soft.noise_type = 4
		general_noise_soft.frequency = 0.1
		general_noise_soft.fractal_weighted_strength = 1
		colornoise.noise_type = 4
		colornoise.frequency = 2.0
		colornoise.domain_warp_enabled = false
		colornoise.fractal_gain = 0.5
		colornoise.fractal_lacunarity = 2
		colornoise.fractal_octaves = 5
		colornoise.fractal_ping_pong_strength = 2
		colornoise.fractal_type = 1
		colornoise.fractal_weighted_strength = 0
		noise3d.noise_type = 4
		noise3d.frequency = 1.5
		noise3d.domain_warp_enabled = false
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
		land_color_2 = Color('4d6032')
		land_color_3 = Color('b3814c')
		low_land_color = Color('4a6c3f')
		low_land_bottom_threshold = 0.5
		low_land_top_threshold = 0.9
		sand_color = Color('9f876b')
		water_color = Color('0541ff')
		deep_water_color = Color('000a4a')
		shallow_water_color = Color('2091bf')
		sand_threshold = 1.1
		water_offset = 1.09
		ocean = true
		snow_random_low = 0.7
		snow_random_high = 0.8
		max_terrain_height_unclamped = 1.34
		global.planet_height_for_ufo = 0.0
		min_terrain_height_unclamped = 0.65
		craters = true
		craters_to_mountains = true
		crater_height_curve = earth_mountain_curve
		mountain_shift_curve = earth_mountain_shift_curve
		mountain_color_curve = earth_mountain_color_curve
		land_color_ease_curve = earth_color_ease_curve
		mountain_color = Color('ab8773')
		manual_mountain_color = true
		num_craters = 20
		crater_size_multiplier = 3.0
		crater_height_multiplier = 1.2
		snow = true
		mantle.mesh.material = mantle_earth_2_material
		lava_lamp.light_color = lava_lamp_color_earth
		lava_lamp.visible = true
		h_bands = false
		craters_to_storms = false
		rings.visible = false
	elif planet_style == 5:
		## mars
		mountain_noise.noise_type = 4
		mountain_noise.frequency = 5.0
		mountain_noise.fractal_weighted_strength = 0
		general_noise_soft.noise_type = 4
		general_noise_soft.frequency = 0.1
		general_noise_soft.fractal_weighted_strength = 1
		canyon_noise.frequency = 1.7
		colornoise.noise_type = 4
		colornoise.frequency = 2.0
		colornoise.domain_warp_enabled = false
		colornoise.fractal_gain = 0.5
		colornoise.fractal_lacunarity = 2
		colornoise.fractal_octaves = 5
		colornoise.fractal_ping_pong_strength = 2
		colornoise.fractal_type = 1
		colornoise.fractal_weighted_strength = 0
		noise3d.noise_type = 4
		noise3d.frequency = 1.6
		noise3d.domain_warp_enabled = false
		noise3d.fractal_gain = 0.5
		noise3d.fractal_lacunarity = 2.0
		noise3d.fractal_octaves = 8
		noise3d.fractal_ping_pong_strength = 2.0
		noise3d.fractal_type = 1
		noise3d.fractal_weighted_strength = 0.0
		ocean = false
		snow_random_low = 0.9
		snow_random_high = 0.94
		max_terrain_height_unclamped = 1.3
		min_terrain_height_unclamped = 0.7
		global.planet_height_for_ufo = 0.0
		craters = true
		craters_to_mountains = true
		num_craters = 1
		crater_size_multiplier = 5.0
		crater_height_multiplier = 1.5
		crater_height_curve = mars_mountain_curve
		canyons = true
		num_canyons = 2
		low_crust_color = Color('5e1c18')
		crust_color = Color('542b18')
		land_snow_color = Color('dbdbdb')
		land_color = Color('8c5323')
		land_color_2 = Color('6f4024')
		land_color_3 = Color('423122')
		land_color_ease_curve = mars_color_ease_curve
		low_land_color = Color('74432e')
		low_land_bottom_threshold = 0.822
		low_land_top_threshold = 0.9
		sand_color = Color('9f876b')
		water_color = Color('0541ff')
		shallow_water_color = Color('2091bf')
		snow = true
		mantle.mesh.material = mantle_mars_2_material
		lava_lamp.light_color = lava_lamp_color_mars
		lava_lamp.visible = true
		h_bands = false
		craters_to_storms = false
		rings.visible = false
	elif planet_style == 4:
		# moon
		colornoise.noise_type = 4
		colornoise.frequency = 3.0
		colornoise.domain_warp_enabled = false
		colornoise.fractal_gain = 0.5
		colornoise.fractal_lacunarity = 2
		colornoise.fractal_octaves = 5
		colornoise.fractal_ping_pong_strength = 2
		colornoise.fractal_type = 1
		colornoise.fractal_weighted_strength = 0.735
		colornoise2.noise_type = 4
		colornoise2.frequency = 5.0
		colornoise2.domain_warp_enabled = false
		colornoise2.fractal_gain = 0.5
		colornoise2.fractal_lacunarity = 2
		colornoise2.fractal_octaves = 5
		colornoise2.fractal_ping_pong_strength = 2
		colornoise2.fractal_type = 1
		colornoise2.fractal_weighted_strength = 0.735
		noise3d.noise_type = 4
		noise3d.frequency = 2.731
		noise3d.domain_warp_enabled = false
		noise3d.fractal_gain = 0.5
		noise3d.fractal_lacunarity = 2.0
		noise3d.fractal_octaves = 5
		noise3d.fractal_ping_pong_strength = 2.0
		noise3d.fractal_type = 1
		noise3d.fractal_weighted_strength = 0.0
		low_crust_color = Color('452e27')
		crust_color = Color('353535')
		land_snow_color = Color('dbdbdb')
		land_color = Color('888888')
		land_color_2 = Color('6a6a6a')
		land_color_3 = Color('464646')
		tint_color = Color('5f78c0')
		tint_color_2 = Color('8a7c40')
		tint_color_3 = Color('b5622d')
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
		global.planet_height_for_ufo = 0.0
		min_terrain_height_unclamped = 0.882
		snow = false
		craters = true
		num_craters = 50
		crater_size_multiplier = 1.566
		crater_height_multiplier = 1.8
		crater_height_curve = moon_crater_curve
		land_color_ease_curve = moon_land_curve
		mantle.mesh.material = mantle_moon_material
		#lava_lamp.light_color = lava_lamp_color_earth
		lava_lamp.visible = false
		h_bands = false
		craters_to_storms = false
		rings.visible = false
	elif planet_style == 6:
		# jupiter
		noise3d.noise_type = 4
		noise3d.frequency = 5.0
		noise3d.domain_warp_enabled = false
		noise3d.fractal_gain = 0.5
		noise3d.fractal_lacunarity = 2.0
		noise3d.fractal_octaves = 5
		noise3d.fractal_ping_pong_strength = 2.0
		noise3d.fractal_type = 1
		noise3d.fractal_weighted_strength = 0.0
		colornoise.noise_type = 4
		colornoise.frequency = 4.0
		colornoise.domain_warp_enabled = false
		colornoise.domain_warp_amplitude = 0.1
		colornoise.fractal_gain = 0.5
		colornoise.fractal_lacunarity = 2
		colornoise.fractal_octaves = 5
		colornoise.fractal_ping_pong_strength = 2
		colornoise.fractal_type = 1
		colornoise.fractal_weighted_strength = 0
		colornoise2.noise_type = 4
		colornoise2.frequency = 3.0
		colornoise2.domain_warp_enabled = true
		colornoise2.domain_warp_amplitude = 0.5
		colornoise2.fractal_gain = 0.8
		colornoise2.fractal_lacunarity = 2
		colornoise2.fractal_octaves = 5
		colornoise2.fractal_ping_pong_strength = 2
		colornoise2.fractal_type = 1
		colornoise2.fractal_weighted_strength = 0.5
		low_crust_color = Color('64788f')
		land_color = Color('a17f61')
		land_color_2 = Color('614739')
		land_color_3 = Color('b7653c')
		ocean = false
		snow_random_low = 0.85
		snow_random_high = 0.95
		max_terrain_height_unclamped = 1.15
		min_terrain_height_unclamped = 0.95
		global.planet_height_for_ufo = 0.1
		snow = false
		craters = true
		num_craters = 1
		crater_size_multiplier = 2.4
		crater_height_multiplier = 1.5
		crater_height_curve = jupiter_storm_curve
		mantle.mesh.material = mantle_jupiter_material
		lava_lamp.light_color = lava_lamp_color_jupiter
		lava_lamp.visible = true
		h_bands = true
		h_band_snap = 0.001
		h_band_wiggle = 0.1
		craters_to_storms = true
		manual_storm_color = true
		storm_color_curve = neptune_storm_color_curve
		storm_color = Color('a85023')
		rings.visible = false
		storm_flatness = 4.0
		turb1 = 0.02
		turb2 = 0.2
		gas_color_ease_curve = jupiter_color_ease_curve
	elif planet_style == 7:
		# saturn
		noise3d.noise_type = 4
		noise3d.frequency = 3.0
		noise3d.domain_warp_enabled = false
		noise3d.fractal_gain = 0.5
		noise3d.fractal_lacunarity = 2.0
		noise3d.fractal_octaves = 5
		noise3d.fractal_ping_pong_strength = 2.0
		noise3d.fractal_type = 1
		noise3d.fractal_weighted_strength = 0.0
		colornoise.noise_type = 4
		colornoise.frequency = 3.0
		colornoise.domain_warp_enabled = false
		colornoise.fractal_gain = 0.5
		colornoise.fractal_lacunarity = 2
		colornoise.fractal_octaves = 5
		colornoise.fractal_ping_pong_strength = 2
		colornoise.fractal_type = 1
		colornoise.fractal_weighted_strength = 0
		colornoise2.noise_type = 4
		colornoise2.frequency = 3.0
		colornoise2.domain_warp_enabled = true
		colornoise2.domain_warp_amplitude = 0.5
		colornoise2.fractal_gain = 0.8
		colornoise2.fractal_lacunarity = 2
		colornoise2.fractal_octaves = 5
		colornoise2.fractal_ping_pong_strength = 2
		colornoise2.fractal_type = 1
		colornoise2.fractal_weighted_strength = 0.5
		low_crust_color = Color('8b79b3')
		land_color = Color('cfac7e')
		land_color_2 = Color('b39368')
		land_color_3 = Color('c79c6d')
		ocean = false
		snow_random_low = 0.85
		snow_random_high = 0.95
		max_terrain_height_unclamped = 1.1
		global.planet_height_for_ufo = 0.05
		min_terrain_height_unclamped = 0.99
		snow = false
		craters = false
		num_craters = 1
		crater_size_multiplier = 2.0
		crater_height_multiplier = 1.5
		crater_height_curve = jupiter_storm_curve
		mantle.mesh.material = mantle_saturn_material
		lava_lamp.light_color = lava_lamp_color_saturn
		lava_lamp.visible = true
		h_bands = true
		h_band_snap = 0.001
		h_band_wiggle = 0.01
		craters_to_storms = false
		rings.visible = true
		turb1 = 0.02
		turb2 = 0.2
		gas_color_ease_curve = saturn_color_ease_curve
	elif planet_style == 8:
		# uranus
		noise3d.noise_type = 4
		noise3d.frequency = 2.0
		noise3d.domain_warp_enabled = false
		noise3d.fractal_gain = 0.5
		noise3d.fractal_lacunarity = 2.0
		noise3d.fractal_octaves = 5
		noise3d.fractal_ping_pong_strength = 2.0
		noise3d.fractal_type = 1
		noise3d.fractal_weighted_strength = 0.0
		colornoise.noise_type = 4
		colornoise.frequency = 5.0
		colornoise.domain_warp_enabled = false
		colornoise.fractal_gain = 0.5
		colornoise.fractal_lacunarity = 2
		colornoise.fractal_octaves = 5
		colornoise.fractal_ping_pong_strength = 2
		colornoise.fractal_type = 1
		colornoise.fractal_weighted_strength = 0
		colornoise2.noise_type = 4
		colornoise2.frequency = 4.0
		colornoise2.domain_warp_enabled = false
		colornoise2.domain_warp_amplitude = 0.5
		colornoise2.fractal_gain = 0.8
		colornoise2.fractal_lacunarity = 2
		colornoise2.fractal_octaves = 5
		colornoise2.fractal_ping_pong_strength = 2
		colornoise2.fractal_type = 1
		colornoise2.fractal_weighted_strength = 0.5
		#low_crust_color = Color('8b94a0')
		low_crust_color = Color('3b5253')
		land_color = Color('7a9cae')
		land_color_2 = Color('739faa')
		land_color_3 = Color('709cbd')
		ocean = false
		snow_random_low = 0.85
		snow_random_high = 0.95
		max_terrain_height_unclamped = 1.08
		global.planet_height_for_ufo = 0.05
		min_terrain_height_unclamped = 0.97
		snow = false
		craters = false
		num_craters = 1
		crater_size_multiplier = 2.0
		crater_height_multiplier = 1.5
		crater_height_curve = jupiter_storm_curve
		mantle.mesh.material = mantle_uranus_material
		lava_lamp.light_color = lava_lamp_color_uranus
		lava_lamp.visible = true
		h_bands = true
		h_band_snap = 0.001
		h_band_wiggle = 0.01
		craters_to_storms = false
		rings.visible = false
		turb1 = 0.02
		turb2 = 0.2
		gas_color_ease_curve = uranus_color_ease_curve
	elif planet_style == 9:
		# neptune
		noise3d.noise_type = 4
		noise3d.frequency = 2.0
		noise3d.domain_warp_enabled = false
		noise3d.fractal_gain = 0.5
		noise3d.fractal_lacunarity = 2.0
		noise3d.fractal_octaves = 5
		noise3d.fractal_ping_pong_strength = 2.0
		noise3d.fractal_type = 1
		noise3d.fractal_weighted_strength = 0.0
		colornoise.noise_type = 4
		colornoise.frequency = 2.0
		colornoise.domain_warp_enabled = false
		colornoise.fractal_gain = 0.5
		colornoise.fractal_lacunarity = 2
		colornoise.fractal_octaves = 5
		colornoise.fractal_ping_pong_strength = 2
		colornoise.fractal_type = 1
		colornoise.fractal_weighted_strength = 0
		colornoise2.noise_type = 4
		colornoise2.frequency = 0.7
		colornoise2.domain_warp_enabled = false
		colornoise2.domain_warp_amplitude = 0.5
		colornoise2.fractal_gain = 0.8
		colornoise2.fractal_lacunarity = 2
		colornoise2.fractal_octaves = 5
		colornoise2.fractal_ping_pong_strength = 2
		colornoise2.fractal_type = 1
		colornoise2.fractal_weighted_strength = 0.5
		#low_crust_color = Color('8b94a0')
		low_crust_color = Color('3f4965')
		land_color = Color('5277c7')
		land_color_2 = Color('476ab5')
		land_color_3 = Color('bcd2e8')
		ocean = false
		snow_random_low = 0.85
		snow_random_high = 0.95
		max_terrain_height_unclamped = 1.08
		global.planet_height_for_ufo = 0.05
		min_terrain_height_unclamped = 0.97
		snow = false
		craters = true
		num_craters = 1
		crater_size_multiplier = 3.2
		crater_height_multiplier = 1.566
		crater_height_curve = neptune_storm_curve
		mantle.mesh.material = mantle_uranus_material
		lava_lamp.light_color = lava_lamp_color_uranus
		lava_lamp.visible = true
		h_bands = true
		h_band_snap = 0.001
		h_band_wiggle = 0.2
		craters_to_storms = true
		rings.visible = false
		manual_storm_color = true
		storm_color_curve = neptune_storm_color_curve
		storm_color = Color('2c456b')
		storm_flatness = 16.0
		turb1 = 0.1
		turb2 = 0.7
		gas_color_ease_curve = neptune_color_ease_curve
	elif planet_style == 10:
		# pluto
		colornoise.noise_type = 4
		colornoise.frequency = 1.0
		colornoise.domain_warp_enabled = true
		colornoise.domain_warp_amplitude = 2
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
		colornoise2.noise_type = 4
		colornoise2.frequency = 5.0
		colornoise2.domain_warp_enabled = false
		colornoise2.fractal_gain = 0.5
		colornoise2.fractal_lacunarity = 2
		colornoise2.fractal_octaves = 5
		colornoise2.fractal_ping_pong_strength = 2
		colornoise2.fractal_type = 1
		colornoise2.fractal_weighted_strength = 0.735
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
		low_crust_color = Color('452e27')
		crust_color = Color('2a2a2a')
		land_snow_color = Color('dbdbdb')
		land_color = Color('b6aeae')
		land_color_2 = Color('cfa474')
		land_color_3 = Color('6f2d25')
		tint_color = Color('523c54')
		tint_color_2 = Color('5e3a37')
		tint_color_3 = Color('4e4428')
		low_land_color = Color('e3d5cb')
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
		global.planet_height_for_ufo = 0.0
		min_terrain_height_unclamped = 0.882
		snow = false
		craters = true
		num_craters = 20
		crater_size_multiplier = 1.5
		crater_height_multiplier = 0.4
		crater_height_curve = mercury_crater_curve
		land_color_ease_curve = pluto_color_ease_curve
		mantle.mesh.material = mantle_moon_material
		#lava_lamp.light_color = lava_lamp_color_earth
		lava_lamp.visible = false
		h_bands = false
		craters_to_storms = false
		rings.visible = false
	elif planet_style == 11:
		## watermelon
		mountain_noise.noise_type = 4
		mountain_noise.frequency = 5.0
		mountain_noise.fractal_weighted_strength = 0
		general_noise_soft.noise_type = 4
		general_noise_soft.frequency = 0.1
		general_noise_soft.fractal_weighted_strength = 1
		colornoise.noise_type = 4
		colornoise.frequency = 2.0
		colornoise.domain_warp_enabled = false
		colornoise.fractal_gain = 0.5
		colornoise.fractal_lacunarity = 2
		colornoise.fractal_octaves = 5
		colornoise.fractal_ping_pong_strength = 2
		colornoise.fractal_type = 1
		colornoise.fractal_weighted_strength = 0
		noise3d.noise_type = 4
		noise3d.frequency = 1.5
		noise3d.domain_warp_enabled = false
		noise3d.fractal_gain = 0.5
		noise3d.fractal_lacunarity = 2.0
		noise3d.fractal_octaves = 5
		noise3d.fractal_ping_pong_strength = 2.0
		noise3d.fractal_type = 1
		noise3d.fractal_weighted_strength = 0.0
		low_crust_color = Color('6e2e0c')
		crust_color = Color('3f3227')
		land_snow_color = Color('dbdbdb')
		land_color = Color('ac5c22')
		land_color_2 = Color('7e4e24')
		land_color_3 = Color('b35639')
		low_land_color = Color('5b2716')
		low_land_bottom_threshold = 0.5
		low_land_top_threshold = 0.9
		sand_color = Color('9f876b')
		water_color = Color('b59e87')
		water_color_2 = Color('8f6f59')
		water_color_3 = Color('c2aca0')
		deep_water_color = Color('853403')
		shallow_water_color = Color('b59e87')
		sand_threshold = 1.1
		water_offset = 1.2
		ocean = true
		snow_random_low = 0.7
		snow_random_high = 0.8
		max_terrain_height_unclamped = 1.2
		global.planet_height_for_ufo = 0.0
		min_terrain_height_unclamped = 0.75
		craters = true
		craters_to_mountains = true
		crater_height_curve = earth_mountain_curve
		mountain_shift_curve = earth_mountain_shift_curve
		mountain_color_curve = earth_mountain_color_curve
		land_color_ease_curve = venus_color_ease_curve
		mountain_color = Color('ab8773')
		manual_mountain_color = true
		num_craters = 20
		crater_size_multiplier = 2.0
		crater_height_multiplier = 0.7
		snow = false
		mantle.mesh.material = mantle_earth_2_material
		lava_lamp.light_color = lava_lamp_color_earth
		lava_lamp.visible = true
		h_bands = false
		craters_to_storms = false
		rings.visible = false
	parameters_set = true

### DONE ###
func snap_to_existing(vec: Vector3, vectree: Dictionary):
	var tree_vec = vec.snapped(treesnap)
	var tv_up = Vector3(tree_vec.x, tree_vec.y + treestep, tree_vec.z)
	var tv_up_l = Vector3(tree_vec.x - treestep, tree_vec.y + treestep, tree_vec.z)
	var tv_up_l_f = Vector3(tree_vec.x - treestep, tree_vec.y + treestep, tree_vec.z - treestep)
	var tv_up_l_b = Vector3(tree_vec.x - treestep, tree_vec.y + treestep, tree_vec.z + treestep)
	var tv_up_r = Vector3(tree_vec.x + treestep, tree_vec.y + treestep, tree_vec.z)
	var tv_up_r_f = Vector3(tree_vec.x + treestep, tree_vec.y + treestep, tree_vec.z - treestep)
	var tv_up_r_b = Vector3(tree_vec.x + treestep, tree_vec.y + treestep, tree_vec.z + treestep)
	var tv_up_f = Vector3(tree_vec.x, tree_vec.y + treestep, tree_vec.z - treestep)
	var tv_up_b = Vector3(tree_vec.x, tree_vec.y + treestep, tree_vec.z + treestep)
	var tv_down = Vector3(tree_vec.x, tree_vec.y - treestep, tree_vec.z)
	var tv_down_l = Vector3(tree_vec.x - treestep, tree_vec.y - treestep, tree_vec.z)
	var tv_down_l_f = Vector3(tree_vec.x - treestep, tree_vec.y - treestep, tree_vec.z - treestep)
	var tv_down_l_b = Vector3(tree_vec.x - treestep, tree_vec.y - treestep, tree_vec.z + treestep)
	var tv_down_r = Vector3(tree_vec.x + treestep, tree_vec.y - treestep, tree_vec.z)
	var tv_down_r_f = Vector3(tree_vec.x + treestep, tree_vec.y - treestep, tree_vec.z - treestep)
	var tv_down_r_b = Vector3(tree_vec.x + treestep, tree_vec.y - treestep, tree_vec.z + treestep)
	var tv_down_f = Vector3(tree_vec.x, tree_vec.y - treestep, tree_vec.z - treestep)
	var tv_down_b = Vector3(tree_vec.x, tree_vec.y - treestep, tree_vec.z + treestep)
	var tv_left = Vector3(tree_vec.x - treestep, tree_vec.y, tree_vec.z)
	var tv_left_f = Vector3(tree_vec.x - treestep, tree_vec.y, tree_vec.z - treestep)
	var tv_left_b = Vector3(tree_vec.x - treestep, tree_vec.y, tree_vec.z + treestep)
	var tv_right = Vector3(tree_vec.x + treestep, tree_vec.y, tree_vec.z)
	var tv_right_f = Vector3(tree_vec.x + treestep, tree_vec.y, tree_vec.z - treestep)
	var tv_right_b = Vector3(tree_vec.x + treestep, tree_vec.y, tree_vec.z + treestep)
	var tv_fwd = Vector3(tree_vec.x, tree_vec.y, tree_vec.z - treestep)
	var tv_back = Vector3(tree_vec.x, tree_vec.y, tree_vec.z + treestep)
	if !vectree.has(tree_vec):
		vectree[tree_vec] = PackedVector3Array([vec])
	else:
		var found = false
		for shift in [tree_vec, tv_up, tv_down, tv_left, tv_right, tv_fwd, tv_back,
					tv_up_l, tv_up_l_f, tv_up_l_b, tv_up_r, tv_up_r_f, tv_up_r_b,
					tv_up_f, tv_up_b,
					tv_down_l, tv_down_l_f, tv_down_l_b, tv_down_r, tv_down_r_f, tv_down_r_b,
					tv_down_f, tv_down_b,
					tv_left_f, tv_left_b, tv_right_f, tv_right_b]:
			if vectree.has(shift):
				for pt in vectree[shift]:
					if vec.distance_squared_to(pt) < max_distance_between_vecs:# or vec.is_equal_approx(pt):
						vec = pt
						found = true
						break
			if found: break
		if !found:
			vectree[tree_vec].append(vec)
	return vec

func craterize():
	for cr in num_craters:
		var impact: Vector3
		var strength: float
		if !craters_to_storms and !craters_to_mountains:
			impact = Vector3(randfn(0.0, 1.0), randfn(0.0, 1.0), randfn(0.0, 1.0)).normalized()
			strength = randfn(3.0, 1.5)
		else:
			impact = Vector3(randfn(0.0, 1.0), randfn(0.0, 0.25), randfn(0.0, 1.0)).normalized()
			strength = randfn(4.0, 1.0)
#		if impact.is_equal_approx(Vector3.UP):
#			impact.y -= 0.05
#			impact = impact.normalized()
#		elif impact.is_equal_approx(Vector3.DOWN):
#			impact.y += 0.05
#			impact = impact.normalized()
		crater_array.append([impact, strength])
	if craters_to_mountains and num_craters > 1:
		for i in 20:
			crater_array = shift_mountains(crater_array)

func canyonize():
	for ca in num_canyons:
		var loc: Vector3
		var depth: float
		loc = Vector3(randfn(0.0, 1.0), randfn(0.0, 0.25), randfn(0.0, 1.0)).normalized()
		depth = randfn(3.0, 0.3)
		if planet_style == 5:
			for om in crater_array:
				if loc.angle_to(om[0]) < PI/5.0:
					var ax = loc.cross(om[0]).normalized()
					loc = loc.rotated(ax, -PI/3.0)
		canyon_array.append([loc, depth])

func _generate_terrain(
		vbdict: Dictionary,
		og_verts: PackedVector3Array,
		vectree: Dictionary
		):
	var pieces_stayed := 0
	var circle_idx := 0
	var newlands = vbdict.duplicate()
	for r in sub_triangle_recursion+1:
		newlands = fill_border_halfways(newlands.duplicate(), og_verts, vectree)
	for bak in vbdict.keys():
		var land_triangles = PackedVector3Array()
		var land_tri_normals = PackedVector3Array()
		var land_tri_colors = PackedColorArray()
		var water_triangles = PackedVector3Array()
		var water_tri_normals = PackedVector3Array()
		var water_tri_colors = PackedColorArray()
		var tree_locations = PackedVector3Array()
		
		var arrays = [land_triangles, land_tri_normals, land_tri_colors,
			water_triangles, water_tri_normals, water_tri_colors,
			tree_locations]
		var new_land_array = newlands[bak]
		
		### this is where the walls are built
		var WALL_STUFF = make_walls(
			og_verts,
			bak,
			new_land_array,
			crust_thickness,
			vectree
			)
		var land_array = vbdict[bak]
		
		### i suspect the missing triangle happens here
		for b in len(land_array)-1:
			var v0 = land_array[b].snapped(Vector3(vsnap, vsnap, vsnap))
			var v1 = land_array[b+1].snapped(Vector3(vsnap, vsnap, vsnap))
			var vp = og_verts[bak].snapped(Vector3(vsnap, vsnap, vsnap))
			v0 = snap_to_existing(v0, vectree)
			v1 = snap_to_existing(v1, vectree)
			vp = snap_to_existing(vp, vectree)
			_sub_triangle(v0,vp,v1, arrays, vectree)
		
		var dxu = og_verts[bak].cross(Vector3.UP)
		var up = dxu.rotated(og_verts[bak].normalized(), -PI/2)
		
		var newpiece = piece.instantiate()
		newpiece.planet_style = planet_style
		newpiece.wall_vertex = WALL_STUFF[0]
		newpiece.wall_normal = WALL_STUFF[1]
		newpiece.wall_color = WALL_STUFF[2]
		newpiece.vertex = land_triangles
		newpiece.normal = land_tri_normals
		newpiece.color = land_tri_colors
		if planet_style == 3:
			newpiece.tree_positions = tree_locations
			newpiece.trees_on = true
		newpiece.ocean = ocean
		if ocean:
			# dont need to generate ocean stuff if no ocean
			newpiece.vertex_w = water_triangles
			newpiece.normal_w = water_tri_normals
			newpiece.color_w = water_tri_colors
			newpiece.vertex_cw = WALL_STUFF[3]
			newpiece.normal_cw = WALL_STUFF[4]
			newpiece.color_cw = WALL_STUFF[5]
		newpiece.direction = og_verts[bak]
		newpiece.lat = og_verts[bak].angle_to(Vector3(og_verts[bak].x, 0.0, og_verts[bak].z).normalized()) * sign(og_verts[bak].y)
		newpiece.lon = Vector3(og_verts[bak].x, 0.0, og_verts[bak].z).normalized().angle_to(Vector3.FORWARD) * sign(og_verts[bak].x)
		#newpiece.rotation_saver = Quaternion(og_verts[bak], Vector3.BACK) # unused
		puzzle_fits[bak] = og_verts[bak]
		newpiece.idx = bak
		#newpiece.siblings = len(og_verts)
		newpiece.ready_for_launch.connect(_on_ready_for_launch)
		#newpiece.upright_vec = up.normalized()
		newpiece.orient_upright = !global.rotation
		#newpiece.thickness = crust_thickness - 1.0
		if global.rotation:
			var randrot = randf_range(0.0, 2*PI)
			newpiece.random_rotation_offset = randrot
		#newpiece.particle_edges = WALL_STUFF[6]
		newpiece.offset = piece_offset
#		if planet_style < 6: # unused
#			newpiece.sound_type = 0 # unused
#		else: # unused
#			newpiece.sound_type = 1 # unused
		# checking who stays
		if pieces_stayed < pieces_at_start:
			newpiece.remove_from_group('pieces')
			#newpiece.staying = true
			pieces_stayed += 1
		else:
			newpiece.circle_idx = circle_idx
			circle_idx += 1
			ufo_locations[bak] = og_verts[bak]
		
		pieces.call_deferred('add_child', newpiece)

func _sub_triangle(
		p1: Vector3,
		p2: Vector3,
		p3: Vector3,
		arrays: Array,
		vectree: Dictionary,
		recursion := 0,
		shade_min := 0,
		shade_max := 1
		):
#	[land_triangles, land_tri_normals, land_tri_colors,            0, 1, 2
#	water_triangles, water_tri_normals, water_tri_colors, trees]   3, 4, 5 ,6
	if recursion > sub_triangle_recursion:
		var p1old = mm(p1)
		var p2old = mm(p2)
		var p3old = mm(p3)

		# land height
		p1 = snap_to_existing(mm(p1*crust_thickness), vectree)
		p2 = snap_to_existing(mm(p2*crust_thickness), vectree)
		p3 = snap_to_existing(mm(p3*crust_thickness), vectree)
		
		# land color
		var land_colors = [land_color, land_color_2, land_color_3]
		var p1_color: Color
		var p2_color: Color
		var p3_color: Color
		
		if not h_bands:
			p1_color = color_vary(p1old, land_colors)
			p2_color = color_vary(p2old, land_colors)
			p3_color = color_vary(p3old, land_colors)
		else:
			p1_color = gas_color_vary(p1old, land_colors)
			p2_color = gas_color_vary(p2old, land_colors)
			p3_color = gas_color_vary(p3old, land_colors)
		
		var p1_lat = asin(abs(p1.normalized().y)) / (PI/2)
		var p2_lat = asin(abs(p2.normalized().y)) / (PI/2)
		var p3_lat = asin(abs(p3.normalized().y)) / (PI/2)
		
		var too_far_north := false
		
		if ocean or snow:
			if p1.length_squared() < pow(sand_threshold, 2) and ocean:
				p1_color = sand_color
			elif p1_lat > snow_start and snow:
				too_far_north = true
				p1_color = p1_color.lerp(land_snow_color, clamp(remap(p1_lat, snow_start, snow_random_high, 0.0, 1.0), 0.0, 1.0))
			if p2.length_squared() < pow(sand_threshold, 2) and ocean:
				p2_color = sand_color
			elif p2_lat > snow_start and snow:
				too_far_north = true
				p2_color = p2_color.lerp(land_snow_color, clamp(remap(p2_lat, snow_start, snow_random_high, 0.0, 1.0), 0.0, 1.0))
			if p3.length_squared() < pow(sand_threshold, 2) and ocean:
				p3_color = sand_color
			elif p3_lat > snow_start and snow:
				too_far_north = true
				p3_color = p3_color.lerp(land_snow_color, clamp(remap(p3_lat, snow_start, snow_random_high, 0.0, 1.0), 0.0, 1.0))
		
		if ocean:
			# water height
			var p1w = p1.normalized() * water_offset
			var p2w = p2.normalized() * water_offset
			var p3w = p3.normalized() * water_offset
			
			# water depth
			var p1w_depth = p1.length_squared() - p1w.length_squared()
			var p2w_depth = p2.length_squared() - p2w.length_squared()
			var p3w_depth = p3.length_squared() - p3w.length_squared()
			
			# water color
			var p1w_color: Color
			var p2w_color: Color
			var p3w_color: Color
			if planet_style == 2:
				var water_colors = [water_color, water_color_2, water_color_3]
				p1w_color = venus_color_vary(p1w, water_colors)
				p2w_color = venus_color_vary(p2w, water_colors)
				p3w_color = venus_color_vary(p3w, water_colors)
			else:
				var depth_start = 0.001
				var depth_end = 0.05
				p1w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-p1w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
				p2w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-p2w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
				p3w_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-p3w_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
			
			# water triangles
			if (p1w_depth < 0.05 and p2w_depth < 0.05 and p3w_depth < 0.05):
				_triangle(p1w, p2w, p3w, arrays[3])
				_triangle(p1w.normalized(), p2w.normalized(), p3w.normalized(), arrays[4])
				_tricolor(p1w_color, p2w_color, p3w_color, arrays[5])
		
		# land triangles
		var pl = Plane(p1, p2, p3)
		var n = pl.normal
		
		if too_far_north and randfn(0.0, 1.0) > 2.0:
			too_far_north = false
		var fertilizer = clamp(tree_noise.get_noise_3dv(pl.get_center()), 0.0, 1.0)
#		if n.dot(pl.get_center().normalized()) > -0.5:
#			too_far_north = true
		#print(fertilizer)
		# plant trees
		if randfn(0.0, 0.7) > (1.5 - fertilizer) and not too_far_north and planet_style == 3:
			var pts = [p1, p2, p3]
			var ctr = pl.get_center()
			var treespot = pts.pick_random().lerp(pts.pick_random(), randf_range(0.0, 1.0))
			if treespot.length() - water_offset > (0.03 + randfn(0.0, 0.001)):
				arrays[6].append(treespot)
		
		_triangle(p1, p2, p3, arrays[0])
		if !h_bands:
			_triangle(n,n,n, arrays[1])
		else:
			_triangle(p1.normalized(), p2.normalized(), p3.normalized(), arrays[1])
		_tricolor(p1_color, p2_color, p3_color, arrays[2])
		
		
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
			newpoint = newpoint.normalized()
			var p12 = newpoint.snapped(Vector3(vsnap, vsnap, vsnap))
			
			ax = p2.cross(p3).normalized()
			newpoint = p2.rotated(ax, ang2*0.5)
			newpoint = newpoint.normalized()
			var p23 = newpoint.snapped(Vector3(vsnap, vsnap, vsnap))
			
			ax = p1.cross(p3).normalized()
			newpoint = p1.rotated(ax, ang3*0.5)
			newpoint = newpoint.normalized()
			var p31 = newpoint.snapped(Vector3(vsnap, vsnap, vsnap))
			
			p12 = snap_to_existing(p12, vectree)
			p23 = snap_to_existing(p23, vectree)
			p31 = snap_to_existing(p31, vectree)
			
			_sub_triangle(p1, p12, p31, arrays, vectree, recursion)
			
			_sub_triangle(p12, p2, p23, arrays, vectree, recursion)
			
			_sub_triangle(p31, p23, p3, arrays, vectree, recursion)
			
			_sub_triangle(p12, p23, p31, arrays, vectree, recursion)

### DONE ###
func make_walls(og_verts: PackedVector3Array,
		og_idx: int,
		ring_array: PackedVector3Array,
		thickness: float,
		vectree: Dictionary,
		water := true,
		):
	var wall_triangles = PackedVector3Array()
	var wall_tri_colors = PackedColorArray()
	var wall_tri_normals = PackedVector3Array()
	var cutwater_triangles = PackedVector3Array()
	var cutwater_tri_normals = PackedVector3Array()
	var cutwater_tri_colors = PackedColorArray()
	var edges_for_particles = PackedVector3Array()

	for b in len(ring_array)-1:
		var v0 = ring_array[b].snapped(Vector3(vsnap, vsnap, vsnap))
		var v1 = ring_array[b+1].snapped(Vector3(vsnap, vsnap, vsnap))
		v0 = snap_to_existing(v0, vectree)
		v1 = snap_to_existing(v1, vectree)
		var v0p = mm(v0*thickness)
		var v0pw = v0p.normalized()*water_offset
		var v0pw_depth = v0p.length_squared() - v0pw.length_squared()
		var v1p = mm(v1*thickness)
		var v1pw = v1p.normalized()*water_offset
		var v1pw_depth = v1p.length_squared() - v1pw.length_squared()
		if !ocean:
			edges_for_particles.append(v0p)
			edges_for_particles.append(v1p)
		else:
			if v0p.length_squared() < v0pw.length_squared():
				edges_for_particles.append(v0pw)
			else:
				edges_for_particles.append(v0p)
			if v1p.length_squared() < v1pw.length_squared():
				edges_for_particles.append(v1pw)
			else:
				edges_for_particles.append(v1p)
		
		var vp = mm(og_verts[og_idx]*thickness)
		var vpw = vp.normalized()*water_offset
		var vpw_depth = vp.length_squared() - vpw.length_squared()
		
		var depth_start = 0.001
		var depth_end = 0.05
		var underwater_depth_start = 0.001
		var underwater_depth_end = 0.03
		var v0pw_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v0pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		var v1pw_color = shallow_water_color.lerp(water_color, clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), depth_start, depth_end, 0.0, 1.0), 0.0, 1.0))
		var n: Vector3
		
		## PIECE WALLS BEGIN ## -----------------------------
		
		if !h_bands:
			_triangle(v0, v0p, v1, wall_triangles)
			
			_tricolor(low_crust_color, crust_color, low_crust_color, wall_tri_colors)
			
			n = Plane(v0, v0p, v1).normal
			_triangle(n, n, n, wall_tri_normals)
			
			###
			
			_triangle(v1, v0p, v1p, wall_triangles)
			
			_tricolor(low_crust_color, crust_color, crust_color, wall_tri_colors)
			
			n = Plane(v1, v0p, v1p).normal
			_triangle(n, n, n, wall_tri_normals)
			
			var wo2 = pow(water_offset, 2.0)
			
			if v0p.length_squared() < wo2 and v1p.length_squared() < wo2:
				_triangle(v0p.limit_length(water_offset), v0pw, v1p.limit_length(water_offset), cutwater_triangles)
			else:
				_triangle(v0p.limit_length(water_offset), v0pw.lerp(vp, 0.004), v1p.limit_length(water_offset), cutwater_triangles)
			
			var c1 = v0pw_color.lerp(deep_water_color, clamp(remap(clamp(-v0pw_depth, 0.0, 1.0), underwater_depth_start, underwater_depth_end, 0.0, 1.0), 0.1, 1.0))
			var c3 = v1pw_color.lerp(deep_water_color, clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), underwater_depth_start, underwater_depth_end, 0.0, 1.0), 0.1, 1.0))
			_tricolor(c1, v0pw_color, c3, cutwater_tri_colors)
			
			n = Plane(v0p,v0pw,v1p).normal
			_triangle(n, n, n, cutwater_tri_normals)
			
			###
			if v0p.length_squared() < wo2 and v1p.length_squared() < wo2:
				_triangle(v1p.limit_length(water_offset), v0pw, v1pw, cutwater_triangles)
			else:
				_triangle(v1p.limit_length(water_offset), v0pw.lerp(vp, 0.004), v1pw.lerp(vp, 0.004), cutwater_triangles)
			#_triangle(v1p.limit_length(water_offset), v0pw.lerp(vp, 0.001), v1pw.lerp(vp, 0.001), cutwater_triangles)
			
			c1 = v1pw_color.lerp(deep_water_color, clamp(remap(clamp(-v1pw_depth, 0.0, 1.0), underwater_depth_start, underwater_depth_end, 0.0, 1.0), 0.0, 1.0))
			_tricolor(c1, v0pw_color, v1pw_color, cutwater_tri_colors)
			
			n = Plane(v1p,v0pw,v1pw).normal
			_triangle(n, n, n, cutwater_tri_normals)
		else:
			
			
#			v0p = v0p.normalized() * 1.2
#			v1p = v1p.normalized() * 1.2
#			vp = vp.normalized() * 1.2
			
			
			var v0_atmo_thickness = v0.distance_to(v0p)
			var v1_atmo_thickness = v1.distance_to(v1p)
			var land_colors = [land_color, land_color_2, land_color_3]
			
			# quarter way up
			var v01 = v0.move_toward(v0p, v0_atmo_thickness * 0.25)
			var v01_color = gas_color_vary(mm(v0)*0.97, land_colors).lerp(low_crust_color, 0.75)
			var v11 = v1.move_toward(v1p, v1_atmo_thickness * 0.25)
			var v11_color = gas_color_vary(mm(v1)*0.97, land_colors).lerp(low_crust_color, 0.75)
			
			# halfway up
			var v02 = v0.move_toward(v0p, v0_atmo_thickness * 0.5)
			var v02_color = gas_color_vary(mm(v0)*0.98, land_colors).lerp(low_crust_color, 0.5)
			var v12 = v1.move_toward(v1p, v1_atmo_thickness * 0.5)
			var v12_color = gas_color_vary(mm(v1)*0.98, land_colors).lerp(low_crust_color, 0.5)
			
			# three quarters up
			var v03 = v0.move_toward(v0p, v0_atmo_thickness * 0.75)
			var v03_color = gas_color_vary(mm(v0)*0.99, land_colors).lerp(low_crust_color, 0.25)
			var v13 = v1.move_toward(v1p, v1_atmo_thickness * 0.75)
			var v13_color = gas_color_vary(mm(v1)*0.99, land_colors).lerp(low_crust_color, 0.25)
			
			var v0p_color = gas_color_vary(mm(v0), land_colors)
			var v1p_color = gas_color_vary(mm(v1), land_colors)
			
			_triangle(v0, v01, v1, wall_triangles)
			_tricolor(low_crust_color, v01_color, low_crust_color, wall_tri_colors)
			n = Plane(v0, v01, v1).normal
			_triangle(n, n, n, wall_tri_normals)
			
			_triangle(v1, v01, v11, wall_triangles)
			_tricolor(low_crust_color, v01_color, v11_color, wall_tri_colors)
			n = Plane(v1, v01, v11).normal
			_triangle(n, n, n, wall_tri_normals)
			
			_triangle(v01, v02, v11, wall_triangles)
			_tricolor(v01_color, v02_color, v11_color, wall_tri_colors)
			n = Plane(v01, v02, v11).normal
			_triangle(n, n, n, wall_tri_normals)
			
			_triangle(v11, v02, v12, wall_triangles)
			_tricolor(v11_color, v02_color, v12_color, wall_tri_colors)
			n = Plane(v11, v02, v12).normal
			_triangle(n, n, n, wall_tri_normals)
			
			_triangle(v02, v03, v12, wall_triangles)
			_tricolor(v02_color, v03_color, v12_color, wall_tri_colors)
			n = Plane(v02, v03, v12).normal
			_triangle(n, n, n, wall_tri_normals)
			
			_triangle(v12, v03, v13, wall_triangles)
			_tricolor(v12_color, v03_color, v13_color, wall_tri_colors)
			n = Plane(v12, v03, v13).normal
			_triangle(n, n, n, wall_tri_normals)
			
			_triangle(v03, v0p, v13, wall_triangles)
			_tricolor(v03_color, v0p_color, v13_color, wall_tri_colors)
			n = Plane(v03, v0p, v13).normal
			_triangle(n, n, n, wall_tri_normals)
			
			_triangle(v13, v0p, v1p, wall_triangles)
			_tricolor(v13_color, v0p_color, v1p_color, wall_tri_colors)
			n = Plane(v13, v0p, v1p).normal
			_triangle(n, n, n, wall_tri_normals)
		
		## PIECE WALLS END ## -----------------------------
		
		## PIECE BOTTOM BEGIN ## -----------------------------
		
		_triangle(v1,og_verts[og_idx],v0,wall_triangles)

		_tricolor(low_crust_color,low_crust_color,low_crust_color,wall_tri_colors)

		n = Plane(v1,og_verts[og_idx],v0).normal
		_triangle(n,n,n,wall_tri_normals)
		
		## PIECE BOTTOM END ## -----------------------------
	
	return [wall_triangles, wall_tri_normals, wall_tri_colors,
		cutwater_triangles, cutwater_tri_normals, cutwater_tri_colors,
		edges_for_particles]

### DONE ###
func _triangle(p1: Vector3, p2: Vector3, p3: Vector3, arr: PackedVector3Array):
	arr.append(p1)
	arr.append(p2)
	arr.append(p3)

### DONE ###
func _tricolor(p1: Color, p2: Color, p3: Color, arr: PackedColorArray):
	arr.append(p1)
	arr.append(p2)
	arr.append(p3)

### DONE ###
func verts_to_delaunay_points(og_verts: PackedVector3Array, dtc: Dictionary):
	var result = {}
	var l = len(og_verts)
	for v in l:
		result[v] = PackedVector3Array()
		for dtc_k in dtc.keys():
			if og_verts[v] in dtc_k:
				if !result[v].has(dtc[dtc_k]):
					result[v].append(dtc[dtc_k])
	return result

### DONE ###
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

### DONE ###
func fill_border_halfways(vbdict: Dictionary, og_verts: PackedVector3Array, vectree: Dictionary):
	for vi in vbdict.keys():
		var border_array = vbdict[vi]
		var new_border_array = PackedVector3Array()
		for b in len(border_array):
			var plus1 = b+1
			if plus1 == len(border_array):
				## last one
				plus1 = 0
				var current_border_point = border_array[b].snapped(Vector3(vsnap, vsnap, vsnap))
				var next_border_point = border_array[plus1].snapped(Vector3(vsnap, vsnap, vsnap))
				current_border_point = snap_to_existing(current_border_point, vectree)
				next_border_point = snap_to_existing(next_border_point, vectree)
				if current_border_point != next_border_point:
					var ang = current_border_point.angle_to(next_border_point)
					var ax = current_border_point.cross(next_border_point).normalized()
					new_border_array.append(current_border_point)
					var halfway = current_border_point.rotated(ax, ang/2.0).snapped(Vector3(vsnap, vsnap, vsnap))
					halfway = snap_to_existing(halfway, vectree)
					new_border_array.append(halfway)
					new_border_array.append(next_border_point)
			else:
				var current_border_point = border_array[b].snapped(Vector3(vsnap, vsnap, vsnap))
				var next_border_point = border_array[plus1].snapped(Vector3(vsnap, vsnap, vsnap))
				current_border_point = snap_to_existing(current_border_point, vectree)
				next_border_point = snap_to_existing(next_border_point, vectree)
				if current_border_point != next_border_point:
					var ang = current_border_point.angle_to(next_border_point)
					var ax = current_border_point.cross(next_border_point).normalized()
					if !(new_border_array.has(current_border_point)):
						new_border_array.append(current_border_point)
					var halfway = current_border_point.rotated(ax, ang/2.0).snapped(Vector3(vsnap, vsnap, vsnap))
					halfway = snap_to_existing(halfway, vectree)
					if !(new_border_array.has(halfway)):
						new_border_array.append(halfway)
					if !(new_border_array.has(next_border_point)):
						new_border_array.append(next_border_point)
		vbdict[vi] = new_border_array
	return vbdict

### DONE ###
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
	return tris

### DONE ###
func array_of_points(arr: PackedVector3Array):
	randomize()
	var rx = randfn(0.0, 2.0)
	var ry = randfn(0.0, 2.0)
	var rz = randfn(0.0, 2.0)
	arr.append(Vector3(rx, ry, rz).normalized())
	return arr

### DONE ###
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

func shift_mountains(mountains: Array):
	for m1 in len(mountains):
		for m2 in len(mountains):
			if m1 != m2:
				if mountains[m1] == mountains[m2]:
					mountains[m1] = mountains[m1].rotated((mountains[m2].cross(mountains[m1]).normalized()), PI/32.0)
				var sep = abs(mountains[m1].angle_to(mountains[m2]))
				mountains[m2] = mountains[m2].rotated((mountains[m2].cross(mountains[m1]).normalized()), mountain_shift_curve.sample_baked(sep) * 2.0)
	return mountains

func mm(vec: Vector3):
	var offset = noise3d.get_noise_3dv(vec)
	var newvec: Vector3
#	if !h_bands:
#		offset = noise3d.get_noise_3dv(vec)
#	else:
#		offset = noise3d.get_noise_3dv(Vector3(vec.x * h_band_wiggle, vec.y, vec.z * h_band_wiggle)) * 2.0
	if !h_bands:
		newvec = vec * remap(offset, -1.0, 1.0, min_terrain_height_unclamped, max_terrain_height_unclamped)
		
		if craters: ### CRATERS
			if !craters_to_storms and !craters_to_mountains:
				var my_craters = []
				for cr in crater_array:
					var dist = vec.normalized().distance_squared_to(cr[0])
					var crsize = 0.01 * crater_size_multiplier
					if dist <= cr[1] * crsize:
						var dist_mapped = remap(dist, 0.0, cr[1] * crsize, 0.0, 1.0)
						my_craters.append(dist_mapped)
				for mycr_i in len(my_craters):
					newvec *= 1.0 + (crater_height_curve.sample_baked(my_craters[mycr_i]) * (0.02 * crater_height_multiplier) * ((mycr_i + 1) / len(my_craters)))
			
			elif craters_to_storms: ### STORMS
				var my_craters = []
				for cr in crater_array:
					var dist = vec.normalized().distance_squared_to(cr[0])
					var crsize = 0.01 * crater_size_multiplier
					if dist <= cr[1] * crsize:
						var sideways = cr[0].cross(Vector3.UP).normalized()
						var spl = Plane(cr[0], Vector3.ZERO, Vector3.UP)
						var vecproj = spl.project(vec).normalized()
						var vdist = vecproj.distance_squared_to(cr[0])
						var vdist_mapped = remap(vdist, 0.0, cr[1] * crsize, 1.0, storm_flatness)
						var dist_mapped = remap(dist, 0.0, cr[1] * crsize, 0.0, 1.0)
						my_craters.append(dist_mapped*vdist_mapped)
				for mycr_i in len(my_craters):
					newvec *= 1.0 + (crater_height_curve.sample_baked(my_craters[mycr_i]) * (0.02 * crater_height_multiplier) * ((mycr_i + 1) / len(my_craters)))
			
			elif craters_to_mountains: ### MOUNTAINS
				var my_craters = []
				for cr in crater_array:
					var dist = vec.normalized().distance_squared_to(cr[0])
					var crsize = 0.01 * crater_size_multiplier
					if dist <= cr[1] * crsize:
						var dist_mapped = remap(dist, 0.0, cr[1] * crsize, 0.0, 1.0)
						my_craters.append(dist_mapped)
				for mycr_i in len(my_craters):
					newvec *= 1.0 + (crater_height_curve.sample_baked(my_craters[mycr_i]) * (0.02 * crater_height_multiplier)) * (1.0 + abs(mountain_noise.get_noise_3dv(newvec) * 5.0))
		
		if canyons: ### CANYONS
			var my_canyons = []
			for cn in canyon_array:
				var dist = vec.normalized().distance_squared_to(cn[0])
				var cnsize = 0.01 * canyon_size_multiplier
				if dist <= cn[1] * cnsize:
					var dist_mapped = remap(dist, 0.0, cn[1] * cnsize, 0.0, 1.0)
					my_canyons.append(dist_mapped)
			for mycn_i in len(my_canyons):
				newvec *= 1.0 - (canyon_height_curve.sample_baked(remap(canyon_noise.get_noise_3dv(Vector3(vec.x * 0.4, vec.y, vec.z * 0.4).normalized()), 0.5, 1.0, 0.0, 1.0)) * canyon_fade_curve.sample_baked(my_canyons[mycn_i]))
		
		### height boundaries
		if newvec.length() < 1.02:
			newvec = newvec.normalized() * 1.02
		elif newvec.length() > 1.3:
			newvec = newvec.normalized() * 1.3
	else:
		newvec = vec.normalized() * 1.1
	
	return newvec

func venus_color_vary(vec: Vector3, colors: Array):
	var return_color: Color
	vec = Vector3(vec.x * 0.2, vec.y, vec.z * 0.2)
	var nval = colornoise.get_noise_3dv(vec)
	nval = remap(clamp(nval, -0.1, 0.1), -0.1, 0.1, 0.0, 1.0)
	if nval > 0.5:
		var final_val = remap(nval, 0.5, 1.0, 0.0, 1.0)
		return_color = colors[1].lerp(colors[0], venus_color_ease_curve.sample_baked(final_val))
	elif nval <= 0.5:
		var final_val = remap(nval, 0.0, 0.5, 0.0, 1.0)
		return_color = colors[2].lerp(colors[1], venus_color_ease_curve.sample_baked(final_val))
	return return_color

func gas_color_vary(vec: Vector3, colors: Array, turbulence := 0.2):
	var return_color: Color
	var vec1 = Vector3(vec.x * turb1, vec.y, vec.z * turb1)
	var vec2: Vector3
	var nval: float
	if planet_style == 6 or planet_style == 9:
		vec2 = Vector3(vec.x * turb2, vec.y, vec.z * turb2)
		nval = colornoise.get_noise_3dv(vec1) - colornoise2.get_noise_3dv(vec2)
	else:
		nval = colornoise.get_noise_3dv(vec1)
	var darken = colornoise2.get_noise_3dv(vec1)
	darken = clamp(remap(darken, -0.1, 0.1, 0.0, 0.3), 0.0, 0.3)
	nval = remap(clamp(nval, -0.15, 0.15), -0.15, 0.15, 0.0, 1.0)
	nval = gas_color_ease_curve.sample_baked(nval)
	if nval > 0.5:
		var final_val = remap(nval, 0.5, 1.0, 0.0, 1.0)
		return_color = colors[1].lerp(colors[0], final_val)
	elif nval <= 0.5:
		var final_val = remap(nval, 0.0, 0.5, 0.0, 1.0)
		return_color = colors[2].lerp(colors[1], final_val)
	return_color = return_color.lerp(Color('black'), darken)
	if craters and craters_to_storms and manual_storm_color:
		var my_craters = []
		for cr in crater_array:
			var dist = vec.normalized().distance_squared_to(cr[0])
			var crsize = 0.01 * crater_size_multiplier
			if dist <= cr[1] * crsize:
				var sideways = cr[0].cross(Vector3.UP).normalized()
				var spl = Plane(cr[0], Vector3.ZERO, Vector3.UP)
				var vecproj = spl.project(vec).normalized()
				var vdist = vecproj.distance_squared_to(cr[0])
				var vdist_mapped = remap(vdist, 0.0, cr[1] * crsize, 1.0, storm_flatness)
				var dist_mapped = remap(dist, 0.0, cr[1] * crsize, 0.0, 1.0)
				my_craters.append(pow(1.0 - clamp(dist_mapped*vdist_mapped, 0.0, 1.0), 2.0))
		for mycr_i in len(my_craters):
			return_color = lerp(return_color, storm_color, storm_color_curve.sample_baked(my_craters[mycr_i]))
	return return_color
#	var return_color: Color
#	var vlen = snapped(vec.length(), h_band_snap)
#	var maxlen = max_terrain_height_unclamped
#	var minlen = min_terrain_height_unclamped
#	#if manual_storm_color:
#	vlen = clamp(vlen, min_terrain_height_unclamped, max_terrain_height_unclamped)
#	var halfway = ((max_terrain_height_unclamped - min_terrain_height_unclamped) / 2.0) + min_terrain_height_unclamped
#	if vlen > halfway:
#		# bigger half
#		var tint_val = remap(vlen, halfway, maxlen, 0.0, 1.0)
#		return_color = colors[1].lerp(colors[0], tint_val)
#	else:
#		# smaller half
#		var tint_val = remap(vlen, minlen, halfway, 0.0, 1.0)
#		return_color = colors[2].lerp(colors[1], tint_val)
#	if craters and craters_to_storms and manual_storm_color:
#		var my_craters = []
#		for cr in crater_array:
#			var dist = vec.normalized().distance_squared_to(cr[0])
#			var crsize = 0.01 * crater_size_multiplier
#			if dist <= cr[1] * crsize:
#				var sideways = cr[0].cross(Vector3.UP).normalized()
#				var spl = Plane(cr[0], Vector3.ZERO, Vector3.UP)
#				var vecproj = spl.project(vec).normalized()
#				var vdist = vecproj.distance_squared_to(cr[0])
#				var vdist_mapped = remap(vdist, 0.0, cr[1] * crsize, 1.0, storm_flatness)
#				var dist_mapped = remap(dist, 0.0, cr[1] * crsize, 0.0, 1.0)
#				my_craters.append(pow(1.0 - clamp(dist_mapped*vdist_mapped, 0.0, 1.0), 2.0))
#		for mycr_i in len(my_craters):
#			return_color = lerp(return_color, storm_color, storm_color_curve.sample_baked(my_craters[mycr_i]))
#	return return_color

func color_vary(vec: Vector3, colors: Array):
	var return_color: Color
	var nval = colornoise.get_noise_3dv(vec)
	var nval2 = colornoise2.get_noise_3dv(vec)
	nval = remap(clamp(nval, -0.1, 0.1), -0.1, 0.1, 0.0, 1.0)
	nval2 = remap(clamp(nval2, -0.1, 0.1), -0.1, 0.1, 0.0, 1.0)
	if nval > 0.5:
		var final_val = remap(nval, 0.5, 1.0, 0.0, 1.0)
		return_color = colors[1].lerp(colors[0], land_color_ease_curve.sample_baked(final_val))
	else:
		var final_val = remap(nval, 0.0, 0.5, 0.0, 1.0)
		if planet_style == 3: # earth ### this needs some fixing
			var vlat = asin(abs(vec.normalized().y)) / (PI/2)
			if vlat > 0.3:
				colors[2] = colors[2].lerp(colors[0], clamp(remap(vlat, 0.3, 0.37, 0.0, 1.0) - general_noise_soft.get_noise_3dv(vec), 0.0, 1.0))
		return_color = colors[2].lerp(colors[1], land_color_ease_curve.sample_baked(final_val))
	if planet_style == 4 or planet_style == 1: # moon or mercury
		if nval2 > 0.5:
			var tint_val = remap(nval2, 0.5, 1.0, 0.0, 1.0)
			return_color = return_color.lerp(tint_color_2.lerp(tint_color, tint_val), 0.07)
		else:
			var tint_val = remap(nval2, 0.0, 0.5, 0.0, 1.0)
			return_color = return_color.lerp(tint_color_3.lerp(tint_color_2, tint_val), 0.07)
	
	### geographical feature coloring ###
	if craters and craters_to_mountains and manual_mountain_color:
		var my_craters = []
		for cr in crater_array:
			var dist = vec.normalized().distance_squared_to(cr[0])
			var crsize = 0.01 * crater_size_multiplier
			if dist <= cr[1] * crsize:
				var dist_mapped = remap(dist, 0.0, cr[1] * crsize, 0.0, 1.0)
				my_craters.append(dist_mapped)
		for mycr_i in len(my_craters):
			pass
			return_color = lerp(return_color, mountain_color, clamp(clamp(mountain_color_curve.sample_baked(my_craters[mycr_i]), 0.0, 0.6) * clamp(abs(mountain_noise.get_noise_3dv(vec) * 10.0), 0.5, 1.0), 0.0, 1.0))
			var vl = vec.length()
			return_color = lerp(return_color, land_snow_color, clamp(remap(vl, 1.05, 1.1, 0.0, 1.0), 0.0, mountain_color_curve.sample_baked(my_craters[mycr_i]) * abs(mountain_noise.get_noise_3dv(vec) * 10.0)))
	if canyons:
		var my_canyons = []
		for cn in canyon_array:
			var dist = vec.normalized().distance_squared_to(cn[0])
			var cnsize = 0.01 * canyon_size_multiplier
			if dist <= cn[1] * cnsize:
				var dist_mapped = remap(dist, 0.0, cn[1] * cnsize, 0.0, 1.0)
				my_canyons.append(dist_mapped)
		for mycn_i in len(my_canyons):
			return_color = return_color.lerp(Color('black'), 2.0 * canyon_height_curve.sample_baked(remap(canyon_noise.get_noise_3dv(Vector3(vec.x * 0.4, vec.y, vec.z * 0.4).normalized()), 0.5, 0.9, 0.0, 1.0)) * canyon_fade_curve.sample_baked(my_canyons[mycn_i]))
	if planet_style == 10 and pluto_heart_center.distance_to(vec) < 1.0:
		var heart_proj := pluto_heart_plane.project(vec)
		var heart_local_vec := heart_proj - pluto_heart_center
		var heart_local_y = heart_local_vec.project(pluto_heart_yax).length() * sign(pluto_heart_yax.dot(heart_local_vec))
		var heart_local_x = heart_local_vec.project(pluto_heart_xax).length()
		var heart_2d_vec := Vector2(heart_local_x, heart_local_y)
		if pluto_heart_check(heart_2d_vec * 2.0):
			return_color = pluto_heart_color
	return return_color

### DONE ###
func pluto_heart_check(vec: Vector2):
	if abs(vec.x) < 1.0:
		var ht = pluto_heart_top(vec.x)
		var hb = pluto_heart_bottom(vec.x)
		if vec.y > hb and vec.y < ht:
			return true
	return false

### DONE ###
func pluto_heart_top(x: float):
	return (0.8 * pow(x, 2.0 / 3.0)) + sqrt(1.0 - pow(x, 2.0))

### DONE ###
func pluto_heart_bottom(x: float):
	return (0.8 * pow(x, 2.0 / 3.0)) - sqrt(1.0 - pow(x, 2.0))

### DONE ###
func _piece_fit(delta):
	if current_piece.global_position.normalized().angle_to(current_piece.direction.normalized()) < PI/32:
		if global.rotation:
			if correct_rotation:
				fit_timer += delta
			else:
				fit_timer = 0.0
		else:
			fit_timer += delta
	else:
		fit_timer = 0.0

### DONE ###
func _on_ready_for_launch(_idx):
	var _pieces = get_tree().get_nodes_in_group('pieces')
	for p in _pieces:
		if p.idx == _idx:
			p.reparent(piece_target, false)
			current_piece = p
			current_piece_mesh = current_piece.get_child(0)
			p.position.y = -6.0
			p.in_space = true
			if !p.is_connected('take_me_home', _on_piece_take_me_home):
				p.take_me_home.connect(_on_piece_take_me_home)
			shadow_light._on = true
			space._on = true
			sun._on = false
			#sun_2._on = false
			looking = true

### DONE ###
func _on_piece_take_me_home(_idx):
	shadow_light._on = false
	space._on = false
	sun._on = true
	#sun_2._on = true
	looking = false


func _on_global_wheel_rot_signal(rot):
	var the_rot = fmod(abs(rot), 2*PI)
	if the_rot < (0.0 + (PI/32)) or the_rot > ((2*PI) - (PI/32)):
		correct_rotation = true
	else:
		correct_rotation = false


func _on_global_loaded_pieces_ready(data):
	global.atmo_type = global.generate_type
	if global.generate_type == 7:
		rings.visible = true
	else:
		rings.visible = false
	var pieces_tracked: Dictionary = data[0]
	var loaded_pieces_data: Dictionary = data[1]
	ufo_locations = {}
	var new_circle_idx := 0
	
	for i in loaded_pieces_data.keys():
		var newpiece = piece.instantiate()
		var piece_dict = loaded_pieces_data[i]
		newpiece.random_rotation_offset = piece_dict["random_rotation_offset"]
		newpiece.vertex = piece_dict["vertex"]
		newpiece.normal = piece_dict["normal"]
		newpiece.color = piece_dict["color"]
		newpiece.direction = piece_dict["direction"]
		newpiece.trees_on = piece_dict["trees_on"]
		newpiece.tree_positions = piece_dict["tree_positions"]
		newpiece.ocean = piece_dict["ocean"]
		newpiece.vertex_cw = piece_dict["vertex_cw"]
		newpiece.normal_cw = piece_dict["normal_cw"]
		newpiece.color_cw = piece_dict["color_cw"]
		newpiece.vertex_w = piece_dict["vertex_w"]
		newpiece.normal_w = piece_dict["normal_w"]
		newpiece.color_w = piece_dict["color_w"]
		newpiece.planet_style = piece_dict["planet_style"]
		newpiece.wall_vertex = piece_dict["wall_vertex"]
		newpiece.wall_normal = piece_dict["wall_normal"]
		newpiece.wall_color = piece_dict["wall_color"]
		newpiece.offset = piece_dict["offset"]
		newpiece.lat = piece_dict["lat"]
		newpiece.lon = piece_dict["lon"]
		newpiece.orient_upright = piece_dict["orient_upright"]
		newpiece.idx = piece_dict["idx"]
		newpiece.ready_for_launch.connect(_on_ready_for_launch)
		
		if not pieces_tracked[i]:
			newpiece.remove_from_group("pieces")
		else:
			newpiece.circle_idx = new_circle_idx
			new_circle_idx += 1
			ufo_locations[i] = piece_dict["direction"]
		
		pieces.add_child(newpiece)
		#pieces.call_deferred("add_child", newpiece)
	global.ufo_locations = ufo_locations
	global.ready_to_start = true

### LOADED PIECES DATA STRUCTURE
#	var return_dict := {
#		"random_rotation_offset": n.random_rotation_offset,
#		"vertex": n.vertex,
#		"normal": n.normal,
#		"color": n.color,
#		"direction": n.direction,
#		"trees_on": n.trees_on,
#		"tree_positions": n.tree_positions,
#		"ocean": n.ocean,
#		"vertex_cw": n.vertex_cw,
#		"normal_cw": n.normal_cw,
#		"color_cw": n.color_cw,
#		"vertex_w": n.vertex_w,
#		"normal_w": n.normal_w,
#		"color_w": n.color_w,
#		"planet_style": n.planet_style,
#		"wall_vertex": n.wall_vertex,
#		"wall_normal": n.wall_normal,
#		"wall_color": n.wall_color,
#		"offset": n.offset,
#		"lat": n.lat,
#		"lon": n.lon,
#		"orient_upright": n.random_rotation_offset,
#		"circle_idx": n.circle_idx,
#		"idx": n.idx,
#	}

func _load_title_planet():
	var node_data: Dictionary = global.title_planet.node_data
	var new_circle_idx := 0
	if global.title_planet.planet_style == 7:
		rings.visible = true
	for i in node_data.keys():
		var newpiece = piece.instantiate()
		var piece_dict = node_data[i]
		newpiece.random_rotation_offset = piece_dict["random_rotation_offset"]
		newpiece.vertex = piece_dict["vertex"]
		newpiece.normal = piece_dict["normal"]
		newpiece.color = piece_dict["color"]
		newpiece.direction = piece_dict["direction"]
		newpiece.trees_on = piece_dict["trees_on"]
		newpiece.tree_positions = piece_dict["tree_positions"]
		newpiece.ocean = piece_dict["ocean"]
		newpiece.vertex_cw = piece_dict["vertex_cw"]
		newpiece.normal_cw = piece_dict["normal_cw"]
		newpiece.color_cw = piece_dict["color_cw"]
		newpiece.vertex_w = piece_dict["vertex_w"]
		newpiece.normal_w = piece_dict["normal_w"]
		newpiece.color_w = piece_dict["color_w"]
		newpiece.planet_style = piece_dict["planet_style"]
		newpiece.wall_vertex = piece_dict["wall_vertex"]
		newpiece.wall_normal = piece_dict["wall_normal"]
		newpiece.wall_color = piece_dict["wall_color"]
		newpiece.offset = piece_dict["offset"]
		newpiece.lat = piece_dict["lat"]
		newpiece.lon = piece_dict["lon"]
		newpiece.orient_upright = piece_dict["orient_upright"]
		newpiece.idx = piece_dict["idx"]
		#newpiece.ready_for_launch.connect(_on_ready_for_launch)
		newpiece.remove_from_group("pieces")
		newpiece.add_to_group("title_pieces")
		pieces.add_child(newpiece)
