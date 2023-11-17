extends PopupPanel

@onready var pct = $MarginContainer/VBoxContainer/PuzzleSize/Pct
@onready var pct_fill_slider = $MarginContainer/VBoxContainer/PctFillSlider
@onready var planet_type_option_button = $MarginContainer/VBoxContainer/PlanetType/PlanetTypeOptionButton
@onready var piece_rotation_button = $MarginContainer/VBoxContainer/PieceRotation/PieceRotationButton
@onready var generate = $MarginContainer/VBoxContainer/Generate
@onready var resume = $MarginContainer/VBoxContainer/Resume
@onready var timer = $Timer
@onready var ux = $".."

var global
var total_pieces := 30
var queue_rotation_flag := false

# Called when the node enters the scene tree for the first time.
func _ready():
	size.x = ux.size.x
	position.y = ux.size.y - size.y
	global = get_node('/root/Global')
	global.ready_to_start_signal.connect(_on_global_ready_to_start_signal)
	global.puzzle_done.connect(_on_global_puzzle_done)
	resume.disabled = !global.unfinished_puzzle_exists
	piece_rotation_button.set_pressed_no_signal(global.rotation)
	pct.text = str(global.pieces_at_start) + '/' + str(global.total_pieces)
	pct_fill_slider.set_value_no_signal(global.pieces_at_start)
	pct_fill_slider.max_value = global.total_pieces - 10
	pct_fill_slider.tick_count = global.total_pieces - 10


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_cancel_button_up():
	self.visible = false


func _on_popup_menu_id_pressed(id):
	if id == 0:
		planet_type_option_button.selected = global.generate_type - 1
		self.visible = true


func _on_pct_fill_slider_value_changed(value):
	pct.text = str(value) + '/' + str(global.total_pieces)
	global.pieces_at_start = value


func _on_generate_button_up():
	global.current_puzzle_was_loaded = false
	self.visible = false
	generate.disabled = true
	resume.disabled = true
	global.rotation = queue_rotation_flag
	global.drawing_mode = false
	piece_rotation_button.set_pressed_no_signal(queue_rotation_flag)
	pct.text = str(global.pieces_at_start) + '/' + str(global.total_pieces)
	pct_fill_slider.set_value_no_signal(global.pieces_at_start)
	pct_fill_slider.max_value = global.total_pieces - 10
	pct_fill_slider.tick_count = global.total_pieces - 10
	global.debug_message = "Generate button pressed"
	global.stop_music = true
	global.atmo_type = global.generate_type
	global.puzzle_finished = false


func _on_resume_button_up():
	global.current_puzzle_was_loaded = true
	self.visible = false
	generate.disabled = true
	resume.disabled = true
	global.drawing_mode = false
	global.stop_music = true
	global.puzzle_finished = false


func _on_piece_rotation_button_toggled(button_pressed):
	queue_rotation_flag = button_pressed


func _on_visibility_changed():
	if global:
		global.menu_open = visible


func _on_planet_type_option_button_item_selected(index):
	global.generate_type = index + 1
	global.debug_message = "Planet type selected"


func _on_global_ready_to_start_signal():
	timer.start()


func _on_global_puzzle_done():
	resume.disabled = true


func _on_timer_timeout():
	generate.disabled = false
	resume.disabled = !global.unfinished_puzzle_exists


func _on_ux_resized():
	if ux:
		size.x = ux.size.x
		position.y = ux.size.y - size.y
