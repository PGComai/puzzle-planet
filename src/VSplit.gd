extends VSplitContainer

@export var max_offset: float = 500.0

var viewsize: Vector2
var dragging: bool = false
var framecount: int = 0
var tapped = false
var tapped_down
var min_offset: float

# Called when the node enters the scene tree for the first time.
func _ready():
	viewsize = get_viewport_rect().size
	min_offset = viewsize.x - (viewsize.y/2)+90
	
func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed == false:
			dragging = false
		else:
#			tapped = false
#			if (self.split_offset + 35 + viewsize.y / 2) > event.position.y and event.position.y > (self.split_offset - 35 + viewsize.y / 2):
#				tapped = true
			dragging = true
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	min_offset = viewsize.x - (viewsize.y/2)+90
	self.split_offset = clamp(split_offset, min_offset, max_offset)
	var halfway_dragged = min_offset + (max_offset - min_offset)/2
	
	if !dragging:
		if self.split_offset > halfway_dragged:
			self.split_offset = lerp(float(self.split_offset), max_offset, 0.1)
		else:
			self.split_offset = lerp(float(self.split_offset), min_offset, 0.1)
#	if tapped:
#		if self.split_offset > halfway_dragged:
#			self.split_offset = lerp(float(self.split_offset), min_offset, 0.1)
#		else:
#			self.split_offset = lerp(float(self.split_offset), max_offset, 0.1)
			

