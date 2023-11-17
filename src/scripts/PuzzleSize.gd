extends HBoxContainer

var global: Node
@onready var pieces_10 = $Pieces10
@onready var pieces_15 = $Pieces15
@onready var pieces_20 = $Pieces20

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pieces_10_button_up():
	pieces_15.set_pressed_no_signal(false)
	pieces_20.set_pressed_no_signal(false)
	pieces_10.set_pressed_no_signal(true)
	global.pieces_at_start = 20


func _on_pieces_15_button_up():
	pieces_10.set_pressed_no_signal(false)
	pieces_20.set_pressed_no_signal(false)
	pieces_15.set_pressed_no_signal(true)
	global.pieces_at_start = 15


func _on_pieces_20_button_up():
	pieces_10.set_pressed_no_signal(false)
	pieces_15.set_pressed_no_signal(false)
	pieces_20.set_pressed_no_signal(true)
	global.pieces_at_start = 10
