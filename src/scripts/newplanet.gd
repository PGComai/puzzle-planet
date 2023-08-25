extends PopupPanel

@onready var pct = $VBoxContainer/PuzzleSize/Pct
@onready var pct_fill_slider = $VBoxContainer/PctFillSlider
@onready var planet_type_option_button = $VBoxContainer/PlanetType/PlanetTypeOptionButton
@onready var rot_button = $VBoxContainer/PieceRotation/RotButton
@onready var generate = $VBoxContainer/Generate

var global
var total_pieces := 30
var queue_rotation_flag := false

# Called when the node enters the scene tree for the first time.
func _ready():
	size.x = get_tree().root.size.x
	position.y = get_tree().root.size.y - size.y
	global = get_node('/root/Global')
	rot_button.set_pressed_no_signal(global.rotation)
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

func _on_check_button_toggled(button_pressed):
	queue_rotation_flag = button_pressed

func _on_generate_button_up():
	self.visible = false
	generate.disabled = true
	global.rotation = queue_rotation_flag
	rot_button.set_pressed_no_signal(queue_rotation_flag)
	pct.text = str(global.pieces_at_start) + '/' + str(global.total_pieces)
	pct_fill_slider.set_value_no_signal(global.pieces_at_start)
	pct_fill_slider.max_value = global.total_pieces - 10
	pct_fill_slider.tick_count = global.total_pieces - 10


func _on_universe_ready_to_start_2():
	generate.disabled = false
