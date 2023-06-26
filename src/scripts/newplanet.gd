extends PopupPanel

@onready var pct = $VBoxContainer/HBoxContainer2/Pct
@onready var pct_fill_slider = $VBoxContainer/PctFillSlider
@onready var option_button = $VBoxContainer/HBoxContainer/OptionButton
@onready var rot_button = $VBoxContainer/HBoxContainer3/CheckButton
@onready var generate = $VBoxContainer/Generate

var global
var total_pieces := 30

# Called when the node enters the scene tree for the first time.
func _ready():
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
		option_button.selected = global.generate_type - 1
		self.visible = true

func _on_pct_fill_slider_value_changed(value):
	pct.text = str(value) + '/' + str(global.total_pieces)
	global.pieces_at_start = value

func _on_check_button_toggled(button_pressed):
	global.rotation = button_pressed

func _on_generate_button_up():
	self.visible = false
	generate.disabled = true
	rot_button.set_pressed_no_signal(global.rotation)
	pct.text = str(global.pieces_at_start) + '/' + str(global.total_pieces)
	pct_fill_slider.set_value_no_signal(global.pieces_at_start)
	pct_fill_slider.max_value = global.total_pieces - 10
	pct_fill_slider.tick_count = global.total_pieces - 10


func _on_universe_ready_to_start_2():
	generate.disabled = false
