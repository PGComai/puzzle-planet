extends Node

signal drawing_mode_changed(mode)
signal piece_in_space_changed(value)

var generate_type := 3
var pieces_at_start := 15
var total_pieces := 30
var rotation := false
var graphics_fancy := false
var sound := true
var vibration := true
var planet_height_for_ufo: float
var pieces_placed_so_far := [0, 0]
var drawing_mode := false:
	set(value):
		drawing_mode = value
		emit_signal('drawing_mode_changed', value)
var change_ez_mantle_value := false
var ez_mantle_proxy := 0.0
var ez_mantle_changed_during_placement := false
var piece_in_space := false:
	set(value):
		piece_in_space = value
		change_ez_mantle_value = true
		emit_signal('piece_in_space_changed', value)

# Called when the node enters the scene tree for the first time.
func _ready():
	RenderingServer.global_shader_parameter_set('ez_mantle_effect', 0.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if change_ez_mantle_value:
		if piece_in_space:
			ez_mantle_proxy = lerp(ez_mantle_proxy, 0.6, 0.05)
			if is_equal_approx(ez_mantle_proxy, 0.6):
				ez_mantle_proxy = 0.6
				change_ez_mantle_value = false
		else:
			ez_mantle_proxy = lerp(ez_mantle_proxy, 0.0, 0.1)
			if is_equal_approx(ez_mantle_proxy, 0.0):
				ez_mantle_proxy = 0.0
				change_ez_mantle_value = false
		RenderingServer.global_shader_parameter_set('ez_mantle_effect', ez_mantle_proxy)
