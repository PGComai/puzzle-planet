extends VSplitContainer

var DEFAULT_SPLIT := 720
var TITLE_SPLIT := 850

var global: Node
var title_up := true
var transition_complete := true
@onready var ux = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.title_screen_signal.connect(_on_global_title_screen_signal)
	if not global.tablet_mode:
		TITLE_SPLIT = ux.size.y - 430
		DEFAULT_SPLIT = max(ux.size.y - 600, ux.size.y / 2)
	else:
		TITLE_SPLIT = ux.size.y / 1.5
		DEFAULT_SPLIT = ux.size.y / 1.8
	global.default_vsplit = DEFAULT_SPLIT
	split_offset = TITLE_SPLIT


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not transition_complete:
		if not title_up:
			split_offset = lerp(split_offset, DEFAULT_SPLIT, 0.05)
			if is_equal_approx(split_offset, DEFAULT_SPLIT):
				split_offset = DEFAULT_SPLIT
				transition_complete = true
		else:
			split_offset = lerp(split_offset, TITLE_SPLIT, 0.05)
			if is_equal_approx(split_offset, TITLE_SPLIT):
				split_offset = TITLE_SPLIT
				transition_complete = true


func _on_global_title_screen_signal(status):
	title_up = status
	transition_complete = false


func _on_ux_resized():
	### ASPECT RATIOS
	# 0.4285 - 21:9 - give more real estate to planet
	# 0.5625 - 16:9 - half and half split is good
	# 0.75 - 4:3 portrait
	# 1.33 - 4:3 landscape
	if ux:
		var ar = ux.size.x / ux.size.y
		if ar < 0.6:
			DEFAULT_SPLIT = max(ux.size.y - 600, ux.size.y / 2)
		else:
			DEFAULT_SPLIT = ux.size.y / 1.8
		transition_complete = false
		global.default_vsplit = DEFAULT_SPLIT
		print(ar)
