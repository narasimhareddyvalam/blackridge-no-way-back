extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await process_frame
	var forest: Node = app.get_node("IndustrialLoop").get("forest")
	var lines := PackedStringArray()
	for body in forest.get_children():
		if body is StaticBody3D:
			for shape in body.get_children():
				var node := shape as CollisionShape3D
				var radius := -1.0
				if node.shape is CylinderShape3D:
					radius = (node.shape as CylinderShape3D).radius
				elif node.shape is CapsuleShape3D:
					radius = (node.shape as CapsuleShape3D).radius
				lines.append("%.4f %.4f %.4f %.4f" % [node.position.x, node.position.z, radius,
					node.position.y])
	var file := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	quit(0)
