extends Node3D

signal i_am_here(idx, ang)
signal ready_for_launch(idx)
signal take_me_home(idx)
signal this_is_my_rotation(rot)
signal drop_off_sound

@export var placement_curve: Curve
@export var scan_bump_curve: Curve

@onready var themesh = $themesh
@onready var walls = $themesh/walls
@onready var water = $themesh/water
@onready var wall_effect = $themesh/wall_effect
@onready var transparent = $transparent
@onready var multi_mesh_instance_3d = $themesh/MultiMeshInstance3D
@onready var invis_timer = $InvisTimer
@onready var placement_delay = $PlacementDelay
@onready var placement_click = $PlacementClick
@onready var click_delay = $ClickDelay

var offset := 1.0

var vertex: PackedVector3Array
var normal: PackedVector3Array
var color: PackedColorArray
var ocean := true

var wall_vertex: PackedVector3Array
var wall_normal: PackedVector3Array
var wall_color: PackedColorArray

var vertex_w: PackedVector3Array
var normal_w: PackedVector3Array
var color_w: PackedColorArray
var water_material = preload("res://tex/water2.tres")
var water_material_nd = preload("res://tex/water2_nodepth.tres")
#var upright_vec: Vector3

var vertex_cw: PackedVector3Array
var normal_cw: PackedVector3Array
var color_cw: PackedColorArray

var direction: Vector3
var idx: int
var circle_idx: int
#var siblings: int
var found = false
var found_spin = 0.0
var good_rot = 0.0
var picked = false
var in_transit = false
var good_pos = Vector3.ZERO
var target_pos
var in_space := false:
	set(value):
		in_space = value
		_in_space_set()
var time_to_return = false
var angle = 0.0
var rot_offset = 0.0
var ax_offset = Vector3.ZERO
var good_global_rot: Vector3
var rad = 10
#var staying = false
var placed := false:
	set(value):
		placed = value
		if value:
			remove_from_group("pieces")
			global.num_pieces_arranged = 0
			placement_delay.start()
#var particle_edges: PackedVector3Array
#var rearrange_offset: int
var repos: Vector3
var rerot: Vector3
var repositioning := false
var orient_upright := true
var off_rot := 0.0
var good_off_rot: Vector3
var zbasis_offset_ax: Vector3
var zbasis_offset := 0.0
var lat := 0.0
var lon := 0.0
#var rotation_saver: Quaternion # unused
var random_rotation_offset := 0.0
var new_up: Vector3
#var thickness: float
var entered := false
var being_abducted := false
var abduction_lerp := 0.0
var abduction_finished := false
var drop_off_finished := true
var drop_off_started := false
var drop_off_original_dist: float
var drop_off_original_position: Vector3
var drop_off_start_pos: Vector3
var planet_style: int


var global
var placement_finished := false
#var sound_type := 0 # unused
var sound_playing := false
var placement_lerp_1 := 0.0
var placement_lerp_2 := 0.0
var placement_wind_up := false

var tree := preload("res://scenes/tree.tscn")
var treemesh := preload("res://tex/tree_mesh_1.tres")
var tree_material := preload("res://tex/tree_1_material.tres")
var tree_positions: PackedVector3Array
var trees_on := false
var tree_color_1 := Color(1.5, 1.5, 1.5)
var tree_color_2 := Color(2.0, 2.0, 2.0)

#@export var built := false ### this will be handy for loading a saved game
var oriented := false
var remember_rotation_z: float

var been_scanned := false
var scanimation := false
var scan_counter := 0.0
var scan_bump_size := 1.2

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	global.pieces.append(self)
	global.ufo_abducting_signal.connect(_on_global_ufo_abducting_signal)
	global.ufo_abduction_done_signal.connect(_on_global_ufo_abduction_done_signal)
	global.wheel_rot_signal.connect(_on_global_wheel_rot_signal)
	global.piece_placed.connect(_on_global_piece_placed)
	global.universe_node.vscan.connect(_on_universe_vscan)
	
	new_up = Vector3.UP.rotated(Vector3.FORWARD, random_rotation_offset)
	remember_rotation_z = random_rotation_offset
#	zbasis_offset_ax = direction.normalized().cross(self.transform.basis.z).normalized()
#	zbasis_offset = direction.normalized().signed_angle_to(self.transform.basis.z, zbasis_offset_ax)
	var newmesh = ArrayMesh.new()
#	var newmesh_transparent = ArrayMesh.new()
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
#	var surface_array_trans = []
#	surface_array_trans.resize(Mesh.ARRAY_MAX)
	
	var temparr = Array(vertex)
	temparr = temparr.map(func(v): return v - direction)
#	var transarray = Array(color)
#	transarray = transarray.map(func(c: Color): return Color(c, 0.5))
	#vertex = PackedVector3Array(temparr)
	surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array(temparr)
	surface_array[Mesh.ARRAY_NORMAL] = normal
	surface_array[Mesh.ARRAY_COLOR] = color
	
#	surface_array_trans[Mesh.ARRAY_VERTEX] = surface_array[Mesh.ARRAY_VERTEX]
#	surface_array_trans[Mesh.ARRAY_NORMAL] = surface_array[Mesh.ARRAY_NORMAL]
#	surface_array_trans[Mesh.ARRAY_COLOR] = PackedColorArray(transarray)
	
	if trees_on:
		#var mmi := MultiMeshInstance3D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = treemesh
		mm.use_colors = true
		#multi_mesh_instance_3d.material_overlay = tree_material
		mm.instance_count = tree_positions.size()
		for tp in tree_positions.size():
			var bas := Basis().looking_at(-tree_positions[tp])
			bas = bas.rotated(tree_positions[tp].normalized(), randf_range(0.0, PI))
			var tf := Transform3D(bas,
								tree_positions[tp] - direction)
			mm.set_instance_transform(tp, tf)
			var clr := tree_color_1.lerp(tree_color_2, clamp(randfn(0.5, 0.5), 0.0, 1.0))
			mm.set_instance_color(tp, clr)
#			var t = tree.instantiate()
#			t.spawn_position = tp - direction
#			themesh.add_child(t)
		mm.visible_instance_count = mm.instance_count
		#multi_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		multi_mesh_instance_3d.multimesh = mm
		#themesh.add_child(mmi)
	
#	var random_vertex = randi_range(0, vertex.size())
#	var t := tree.instantiate()
#	t.spawn_position = vertex[random_vertex]
#	themesh.add_child(t)
	
	newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	#newmesh_transparent.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array_trans)
	
	if ocean:
		surface_array = []
		surface_array.resize(Mesh.ARRAY_MAX)
		
		temparr = Array(vertex_cw)
		temparr = temparr.map(func(v): return v - direction)
		#vertex_cw = PackedVector3Array(temparr)
		
		surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array(temparr)
		surface_array[Mesh.ARRAY_NORMAL] = normal_cw
		surface_array[Mesh.ARRAY_COLOR] = color_cw
		
		newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
		
		if not (len(vertex_w) == 0):
			var watermesh = ArrayMesh.new()
			surface_array = []
			surface_array.resize(Mesh.ARRAY_MAX)
			
			temparr = Array(vertex_w)
			temparr = temparr.map(func(v): return v - direction)
			#vertex_w = PackedVector3Array(temparr)
			
			surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array(temparr)
			surface_array[Mesh.ARRAY_NORMAL] = normal_w
			surface_array[Mesh.ARRAY_COLOR] = color_w
			
			watermesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
			water.mesh = watermesh
			if planet_style == 2:
				water.material_overlay.roughness = 0.6
			else:
				water.material_overlay.roughness = 0.04
	
	themesh.mesh = newmesh
	#transparent.mesh = newmesh_transparent
	if planet_style > 5 and planet_style < 10:
		themesh.material_overlay.roughness = 0.65
	else:
		themesh.material_overlay.roughness = 0.79
	
	var wallmesh = ArrayMesh.new()
	
	surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	temparr = Array(wall_vertex)
	temparr = temparr.map(func(v): return v - direction)
	#wall_vertex = PackedVector3Array(temparr)
	surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array(temparr)
	surface_array[Mesh.ARRAY_NORMAL] = wall_normal
	surface_array[Mesh.ARRAY_COLOR] = wall_color
	
	wallmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	walls.mesh = wallmesh
	
	self.position = direction * offset


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !placed:
#		if !drop_off_finished:
#			_dropped_off_animation()
		if being_abducted:
			_abducted_animation()
		if repositioning:
			self.position = lerp(self.position, repos, 0.1)
			#var dist = position.distance_to(repos)
			self.look_at(Vector3(0.0, self.global_position.y, 0.0), new_up)
			if self.position.is_equal_approx(repos):
				self.position = repos
				self.look_at(Vector3(0.0, self.global_position.y, 0.0), new_up)
				good_global_rot = self.global_rotation
				good_rot = good_global_rot.y
				repositioning = false
				#global.num_pieces_arranged += 1
#				if global.rotation:
#					rotowindow.visible = false
#					print('hide roto')
		else:
			if found:
				found_rotate(delta)
			else:
				self.rotation.y = lerp_angle(self.rotation.y, good_rot, 0.05)
				found_spin = 0.0
#			if picked and in_transit:
#				found = false
#				_picked_animation()
#			elif !picked and in_transit:
#				found = false
#				_unpicked_animation()
			if in_space:
				#print(to_global(upright_vec).angle_to(Vector3.UP))
				found = false
				self.rotation.y = good_global_rot.y - angle
				position.x = 0.0
				position.z = 0.0
				position.y = lerp(self.position.y, 0.0, 0.1)
				if !orient_upright:
					pass
			if time_to_return:
				picked = false
				position.y = lerp(self.position.y, -10.0, 0.1)
				if position.y < -1.5:
					emit_signal('take_me_home', idx)
					time_to_return = false
#			if back_from_space:
#				position = Vector3.ZERO
#				position.y = 20.0
#				in_transit = true
#				back_from_space = false
	else:
		if !placement_finished:
			_placement()
		if scanimation:
			_scanimate(delta)


func _placement():
	if not placement_wind_up:
		global_position = lerp(global_position, direction * 1.1, 0.2)
		if global_position.is_equal_approx(direction * 1.1):
			placement_wind_up = true
			click_delay.start()
	else:
		global_position = lerp(global_position, direction, 0.3)
		if global_position.is_equal_approx(direction):
			rotation.z = 0.0
			global_position = direction
			placement_finished = true
#	if placement_lerp_1 > 0.92 and !sound_playing:
#		if global.sound:
#			#note_player.play()
#			print("click")
#			sound_playing = true
#	placement_lerp_1 = lerp(placement_lerp_1, 1.0, 0.03)
#	placement_lerp_2 = placement_curve.sample_baked(placement_lerp_1)


func arrange(re = false):
	if not re:
		themesh._orient_for_carousel()
	if not get_parent().is_connected('found_you', _on_found_you):
		get_parent().found_you.connect(_on_found_you)
		get_parent().picked_you.connect(_on_picked_you)
		get_parent().ufo_at_angle.connect(_on_ufo_at_angle)
	var brothers = len(get_tree().get_nodes_in_group('pieces'))
	angle = ((2*PI)/brothers) * (circle_idx)
	rad = remap(float(brothers), 20.0, 40.0, 5.0, 10.0)
	var newpos = Vector3(sin(angle),0.0,cos(angle)) * rad
	good_pos = newpos
	var dir = direction.normalized()
	var np = newpos.normalized()
	var off = dir.direction_to(np)
	var ax = dir.cross(off).normalized()
	ax_offset = ax
	var rot = dir.signed_angle_to(np, ax)
	rot_offset = rot
	if not re:
		self.position = newpos
		drop_off_original_position = newpos
		self.look_at(Vector3(0.0, self.global_position.y, 0.0))
		good_global_rot = self.global_rotation
		good_rot = good_global_rot.y
	else:
		repos = newpos
		repositioning = true
	if not orient_upright and not re:
		self.rotate(good_pos.normalized(), random_rotation_offset)
	emit_signal("i_am_here",idx ,snappedf(angle, 0.01))
	#if not re:
	global.num_pieces_arranged += 1
	drop_off_finished = true


func _on_found_you(_idx):
	if idx == _idx and !in_space and !in_transit:
		found = true
	else:
		found = false


func found_rotate(delta):
	found_spin += delta * 10
	self.rotation.y = good_rot + sin(found_spin/20.0)/2.0


func _on_picked_you(_idx):
	if idx == _idx:
		if repositioning:
			self.position = repos
			self.look_at(Vector3(0.0, self.global_position.y, 0.0), new_up)
			good_global_rot = self.global_rotation
			good_rot = good_global_rot.y
			repositioning = false
			print("repositioning hurried up")
		global.placing_piece = not global.placing_piece
		print("placing piece: %s" % global.placing_piece)
		global.chosen_piece = self
		global.wheel_target_rot = remember_rotation_z
#	if in_transit:
#		pass
#	else:
#		if in_space:
#			time_to_return = true
#			global.placing_piece = false
##			if global.rotation and idx == _idx:
##				rotowindow.visible = false
##				#print('hide roto')
#		else:
#			if idx == _idx:
##				if global.rotation:
##					ghost.mesh = themesh.mesh
##					ghostwalls.mesh = walls.mesh
##					ghostwater.mesh = water.mesh
##					#ghostoutline.mesh = themesh.mesh
##					#ghostwallsoutline.mesh = walls.mesh
##					ghost.rotation = themesh.rotation
##					#ghostoutline.rotation = themesh.rotation
##					ghostball.rotation.z = rotation.z
##					rotowindow.visible = true
##					#print('show roto')
#				emit_signal('this_is_my_rotation', self.rotation.z)
#				picked = true
#				in_transit = true
#			else:
#				picked = false


#func _picked_animation():
#	self.position.x = lerp(self.position.x, 0.0, 0.1)
#	self.position.z = lerp(self.position.z, 0.0, 0.1)
#	self.position.y = lerp(self.position.y, 15.0, 0.02)
#	if self.position.y > 7.0:
#		emit_signal("ready_for_launch", idx)
#		in_transit = false
#
#
#func _unpicked_animation():
#	self.position.x = lerp(self.position.x, good_pos.x, 0.02)
#	self.position.z = lerp(self.position.z, good_pos.z, 0.02)
#	self.position.y = lerp(self.position.y, 0.0, 0.1)
#	if self.position.is_equal_approx(Vector3(good_pos.x, 0.0, good_pos.z)):
#		self.position = Vector3(good_pos.x, 0.0, good_pos.z)
#		in_transit = false


func _abducted_animation():
	water.material_overlay.emission_enabled = true
	themesh.material_overlay.emission_enabled = true
	walls.material_overlay.emission_enabled = true
	water.material_overlay.emission_energy_multiplier = lerp(water.material_overlay.emission_energy_multiplier, 1.0, abduction_lerp)
	themesh.material_overlay.emission_energy_multiplier = lerp(themesh.material_overlay.emission_energy_multiplier, 1.0, abduction_lerp)
	walls.material_overlay.emission_energy_multiplier = lerp(walls.material_overlay.emission_energy_multiplier, 1.0, abduction_lerp)
	position = lerp(position, position.normalized() * 1.3, abduction_lerp)
	scale = lerp(scale, Vector3(0.1, 0.1, 0.1), abduction_lerp)
	if abduction_finished:
		position = Vector3.ZERO
		scale = Vector3(1.0, 1.0, 1.0)
		being_abducted = false
		water.material_overlay.emission_enabled = false
		themesh.material_overlay.emission_enabled = false
		walls.material_overlay.emission_enabled = false


func _on_global_ufo_abducting_signal(info):
	if info[0] == idx:
		abduction_lerp = info[1]
		being_abducted = true


func _on_global_ufo_abduction_done_signal():
	if being_abducted:
		abduction_finished = true


func _on_ufo_at_angle(ang, pos):
	if is_equal_approx(ang, angle) and visible == false:
		drop_off_start_pos = pos
		visible = true
		drop_off_finished = false
		emit_signal("drop_off_sound")


func _dropped_off_animation():
	if !drop_off_started:
		position = position.limit_length(drop_off_original_dist - 1.3) + Vector3(0.0, 0.2, 0.0)
		scale = Vector3(0.1, 0.1, 0.1)
		drop_off_started = true
		water.material_overlay.emission_enabled = true
		themesh.material_overlay.emission_enabled = true
		walls.material_overlay.emission_enabled = true
		water.material_overlay.emission_energy_multiplier = 1.0
		themesh.material_overlay.emission_energy_multiplier = 1.0
		walls.material_overlay.emission_energy_multiplier = 1.0
	else:
		water.material_overlay.emission_energy_multiplier = lerp(water.material_overlay.emission_energy_multiplier, 0.0, 0.1)
		themesh.material_overlay.emission_energy_multiplier = lerp(themesh.material_overlay.emission_energy_multiplier, 0.0, 0.1)
		walls.material_overlay.emission_energy_multiplier = lerp(walls.material_overlay.emission_energy_multiplier, 0.0, 0.1)
		position = lerp(position, drop_off_original_position, 0.1)
		scale = lerp(scale, Vector3(1.0, 1.0, 1.0), 0.1)
		if position.is_equal_approx(drop_off_original_position) and scale.is_equal_approx(Vector3(1.0, 1.0, 1.0)):
			water.material_overlay.emission_enabled = false
			themesh.material_overlay.emission_enabled = false
			walls.material_overlay.emission_enabled = false
			position = drop_off_original_position
			scale = Vector3(1.0, 1.0, 1.0)
			drop_off_finished = true


func _on_child_entered_tree(node):
	node.owner = self


func _on_global_wheel_rot_signal(rot):
	if global.chosen_piece == self and not placed:
		rotation.z = rot
		remember_rotation_z = rot


func _in_space_set():
	if not in_space:
		position = Vector3(good_pos.x, 0.0, good_pos.z)
#		themesh.material_overlay.no_depth_test = false
#		water.material_overlay.no_depth_test = false
#		multi_mesh_instance_3d.material_overlay.no_depth_test = false
#		themesh.visible = true
#		transparent.visible = false
	else:
		pass
#		themesh.material_overlay.no_depth_test = true
#		water.material_overlay.no_depth_test = true
#		multi_mesh_instance_3d.material_overlay.no_depth_test = true
#		themesh.visible = false
#		transparent.visible = true


func _disappear():
	visible = false
	invis_timer.start()


func _on_invis_timer_timeout():
	visible = true


func _on_placement_delay_timeout():
	global.placed_cidx = circle_idx


func _on_global_piece_placed(cidx):
	if is_in_group("pieces"):
		if circle_idx > cidx:
			circle_idx -= 1
		arrange(true)


func _on_click_delay_timeout():
	if global.sound:
		placement_click.pitch_scale = randfn(1.0, 0.01)
		placement_click.play()
	if global.vibration:
		Input.vibrate_handheld(5)


func _on_universe_vscan(y):
	if not been_scanned and y < global_position.y:
		scanimation = true
		been_scanned = true


func _scanimate(delta):
	scan_counter += delta
	scan_counter = clamp(scan_counter, 0.0, 1.0)
	var l: float = scan_bump_curve.sample_baked(scan_counter)
	global_position = lerp(direction, direction * scan_bump_size, l)
	if is_equal_approx(scan_counter, 1.0):
		scanimation = false
		scan_counter = 0.0
		global_position = direction
