extends SceneTree
## Leak probe: which particle set-ups print "DummyShader RID leaked" at exit, headless.
## Case comes from the first user argument after "--".

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var case_name: String = OS.get_cmdline_user_args()[0]
	var node: Node
	match case_name:
		"default":
			var p := GPUParticles3D.new()
			p.process_material = ParticleProcessMaterial.new()
			node = p
		"default_curve":
			var p := GPUParticles3D.new()
			var m := ParticleProcessMaterial.new()
			var c := CurveTexture.new()
			c.curve = Curve.new()
			m.alpha_curve = c
			p.process_material = m
			node = p
		"default_turbulence":
			var p := GPUParticles3D.new()
			var m := ParticleProcessMaterial.new()
			m.turbulence_enabled = true
			p.process_material = m
			node = p
		"code_two_draw":
			node = Node3D.new()
			for i in range(2):
				var p := GPUParticles3D.new()
				var m := ParticleProcessMaterial.new()
				m.spread = 20.0 + 10.0 * i
				p.process_material = m
				var q := QuadMesh.new()
				q.material = StandardMaterial3D.new()
				p.draw_pass_1 = q
				node.add_child(p)
		"code_one_draw":
			var p := GPUParticles3D.new()
			p.process_material = ParticleProcessMaterial.new()
			var q := QuadMesh.new()
			q.material = StandardMaterial3D.new()
			p.draw_pass_1 = q
			node = p
		"material_only":
			var m := ParticleProcessMaterial.new()
			m.alpha_curve = CurveTexture.new()
			print("made ", m)
			quit(0)
			return
		_:
			node = (load(case_name) as PackedScene).instantiate()
	root.add_child(node)
	for i in range(5):
		await process_frame
	node.free()
	for i in range(5):
		await process_frame
	print("PROBE DONE ", case_name)
	quit(0)
