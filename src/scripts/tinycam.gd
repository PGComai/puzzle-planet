extends Camera3D

@export var post_processing := true:
	set(p):
		if p:
			$Postprocess.show()
			post_processing = p
			var a = Vector3(-1, 1, 0).normalized()
			var b = Vector3(1, 0, 0).normalized()
			print("dot: ", a.dot(b))
		else:
			$Postprocess.hide()
			post_processing = p
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
