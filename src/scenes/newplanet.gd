extends PopupPanel

@onready var pct = $VBoxContainer/HBoxContainer2/Pct
@onready var pct_fill_slider = $VBoxContainer/PctFillSlider
@onready var option_button = $VBoxContainer/HBoxContainer/OptionButton

var global

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	pct.text = str(global.pct_complete) + '%'
	pct_fill_slider.set_value_no_signal(global.pct_complete)

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
	pct.text = str(value) + '%'
	global.pct_complete = value
