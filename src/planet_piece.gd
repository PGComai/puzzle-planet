extends MeshInstance3D

signal i_am_here(idx, ang)
signal ready_for_launch(idx)
signal take_me_home(idx)

@onready var upward = $upward

var vertex: PackedVector3Array
var normal: PackedVector3Array
var color: PackedColorArray

var vertex_w: PackedVector3Array
var normal_w: PackedVector3Array
var color_w: PackedColorArray
var water_material = preload("res://puzzle planet/water2.tres")
var upright_vec: Vector3

var vertex_cw: PackedVector3Array
var normal_cw: PackedVector3Array
var color_cw: PackedColorArray

var direction: Vector3
var idx: int
var circle_idx: int
var siblings: int
var found = false
var found_spin = 0.0
var good_rot = 0.0
var picked = false
var in_transit = false
var good_pos = Vector3.ZERO
var target_pos
var in_space = false
var time_to_return = false
var back_from_space = false
var angle = 0.0
var rot_offset = 0.0
var ax_offset = Vector3.ZERO
var good_global_rot
var rad = 10
var staying = false
var placed = false
var particle_edges: Array
var rearrange_offset: int

# Called when the node enters the scene tree for the first time.
func _ready():
	upward.position = upright_vec * 0.4
	var newmesh = ArrayMesh.new()
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var temparr = Array(vertex)
	temparr = temparr.map(func(v): return v - direction)
	vertex = PackedVector3Array(temparr)
	surface_array[Mesh.ARRAY_VERTEX] = vertex
	surface_array[Mesh.ARRAY_NORMAL] = normal
	surface_array[Mesh.ARRAY_COLOR] = color
	
	newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	temparr = Array(vertex_cw)
	temparr = temparr.map(func(v): return v - direction)
	vertex_cw = PackedVector3Array(temparr)
	
	surface_array[Mesh.ARRAY_VERTEX] = vertex_cw
	surface_array[Mesh.ARRAY_NORMAL] = normal_cw
	surface_array[Mesh.ARRAY_COLOR] = color_cw
	
	newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	temparr = Array(vertex_w)
	temparr = temparr.map(func(v): return v - direction)
	vertex_w = PackedVector3Array(temparr)
	
	surface_array[Mesh.ARRAY_VERTEX] = vertex_w
	surface_array[Mesh.ARRAY_NORMAL] = normal_w
	surface_array[Mesh.ARRAY_COLOR] = color_w
	
	newmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	mesh = newmesh
	mesh.surface_set_material(mesh.get_surface_count()-1, water_material)
	if staying:
		self.position = direction

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !placed:
		if found:
			found_rotate(delta)
		else:
			self.rotation.y = lerp_angle(self.rotation.y, good_rot, 0.05)
			found_spin = 0.0
		if picked and in_transit:
			found = false
			_picked_animation()
		elif !picked and in_transit:
			found = false
			_unpicked_animation()
		if in_space:
			found = false
			self.rotation.y = good_global_rot.y - angle
			position.x = 0.0
			position.z = 0.0
			position.y = lerp(self.position.y, 0.0, 0.1)
		if time_to_return:
			picked = false
			position.y = lerp(self.position.y, -10.0, 0.1)
			if position.y < -5.0:
				emit_signal('take_me_home', idx)
				time_to_return = false
		if back_from_space:
			position = Vector3.ZERO
			position.y = 20.0
			in_transit = true
			back_from_space = false

func arrange(re = false):
	if !get_parent().is_connected('found_you', _on_found_you):
		get_parent().found_you.connect(_on_found_you)
		get_parent().picked_you.connect(_on_picked_you)
	var brothers = len(get_tree().get_nodes_in_group('pieces'))
	angle = ((2*PI)/brothers) * (circle_idx)
	rad = remap(float(brothers), 20.0, 40.0, 5.0, 10.0)
	var newpos = Vector3(sin(angle),0.0,cos(angle)) * rad
	self.position = newpos
	good_pos = newpos
	if !re:
		var dir = direction.normalized()
		var np = newpos.normalized()
		var off = dir.direction_to(np)
		var ax = dir.cross(off).normalized()
		ax_offset = ax
		var rot = dir.signed_angle_to(np, ax)
		rot_offset = rot
		self.rotate(ax, rot)
		var urv = upright_vec.rotated(ax, rot)
		self.rotate(good_pos.normalized(), urv.signed_angle_to(Vector3.UP, good_pos.normalized()))
	else:
		self.rotate(Vector3.UP, ((((2*PI)/brothers) * (circle_idx))-angle) * -rearrange_offset)
	good_rot = self.rotation.y
	good_global_rot = self.global_rotation
	emit_signal("i_am_here",idx ,snappedf(angle, 0.01))

func _on_found_you(_idx):
	if idx == _idx and !in_space and !in_transit:
		found = true
	else:
		found = false

func found_rotate(delta):
	found_spin += delta * 10
	self.rotation.y = good_rot + sin(found_spin/20.0)/1.2
	
func _on_picked_you(_idx):
	if in_space:
		time_to_return = true
	else:
		if idx == _idx:
			picked = true
			in_transit = true
		else:
			picked = false

func _picked_animation():
	self.position.x = lerp(self.position.x, 0.0, 0.05)
	self.position.z = lerp(self.position.z, 0.0, 0.05)
	self.position.y = lerp(self.position.y, 20.0, 0.02)
	if self.position.y > 12.0:
		emit_signal("ready_for_launch", idx)
		in_transit = false

func _unpicked_animation():
	self.position.x = lerp(self.position.x, good_pos.x, 0.02)
	self.position.z = lerp(self.position.z, good_pos.z, 0.02)
	self.position.y = lerp(self.position.y, 0.0, 0.05)
