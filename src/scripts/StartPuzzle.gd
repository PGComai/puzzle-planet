extends Button

var global

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_universe_ready_to_start_2():
	visible = true

func _on_button_up():
	visible = false
	global.pieces_placed_so_far = [0, global.total_pieces - global.pieces_at_start]
	print(global.pieces_placed_so_far)

func _on_generate_button_up():
	visible = false
