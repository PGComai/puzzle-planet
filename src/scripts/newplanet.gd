extends PopupPanel

@onready var pct = $MarginContainer/VBoxContainer/PuzzleSize/Pct
@onready var pct_fill_slider = $MarginContainer/VBoxContainer/PctFillSlider
@onready var planet_type_option_button = $MarginContainer/VBoxContainer/PlanetType/PlanetTypeOptionButton
@onready var piece_rotation_button = $MarginContainer/VBoxContainer/PieceRotation/PieceRotationButton
@onready var generate = $MarginContainer/VBoxContainer/Generate
@onready var draw = $MarginContainer/VBoxContainer/Draw

var global
var total_pieces := 30
var queue_rotation_flag := false

# Called when the node enters the scene tree for the first time.
func _ready():
	size.x = get_tree().root.size.x
	position.y = get_tree().root.size.y - size.y
	global = get_node('/root/Global')
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
	self.visible = false
	generate.disabled = true
	draw.disabled = true
	global.rotation = queue_rotation_flag
	global.drawing_mode = false
	piece_rotation_button.set_pressed_no_signal(queue_rotation_flag)
	pct.text = str(global.pieces_at_start) + '/' + str(global.total_pieces)
	pct_fill_slider.set_value_no_signal(global.pieces_at_start)
	pct_fill_slider.max_value = global.total_pieces - 10
	pct_fill_slider.tick_count = global.total_pieces - 10
	global.debug_message = "Generate button pressed"


func _on_universe_ready_to_start_2():
	generate.disabled = false
	draw.disabled = false


func _on_draw_button_up():
	visible = false
	global.drawing_mode = true


func _on_piece_rotation_button_toggled(button_pressed):
	queue_rotation_flag = button_pressed


func _on_visibility_changed():
	global.menu_open = visible


func _on_planet_type_option_button_item_selected(index):
	global.generate_type = index + 1
	global.debug_message = "Planet type selected"
