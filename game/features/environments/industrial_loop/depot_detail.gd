extends Node3D

const Build = preload("res://shared/components/mesh_builder.gd")
const PALLET = preload("art/pallet.glb")
const CRATE = preload("art/crate.glb")
const BOLLARD = preload("art/bollard.glb")


func _ready() -> void:
	var rubber := Build.material(Color("161a1c"), 0.94)
	var metal := Build.material(Color("6b716d"), 0.40)
	metal.metallic = 0.7
	var yellow := Build.material(Color("b8933b"), 0.65)
	for x in [-45, -30, -15]:
		for side in [-1, 1]:
			Build.box(self, Vector3(x + side * 4.57, 2.5, 112.08),
				Vector3(0.30, 5.0, 0.38), rubber)
			Build.box(self, Vector3(x + side * 4.87, 2.6, 112.26),
				Vector3(0.10, 5.2, 0.16), metal)
			_place(BOLLARD, Vector3(x + side * 5.15, 0, 110.1))
			Build.box(self, Vector3(x + side * 3.25, 0.43, 112.05),
				Vector3(0.45, 0.7, 0.30), rubber)
		Build.box(self, Vector3(x, 4.95, 112.08), Vector3(9.5, 0.38, 0.38), rubber)
		Build.box(self, Vector3(x, 5.9, 112.08), Vector3(1.0, 0.75, 0.03), yellow)
		var number := Build.text(self, "%02d" % (int((x + 45) / 15) + 1),
			Vector3(x, 5.90, 112.04), 50, Color("181e22"))
		number.rotation.y = PI
		number.pixel_size = 0.012
		for height in [0.9, 1.7, 2.5, 3.3, 4.1]:
			Build.box(self, Vector3(x, height, 112.23), Vector3(8.9, 0.018, 0.018), metal)
		Build.box(self, Vector3(x, 0.13, 111.73), Vector3(8.8, 0.14, 0.80), metal)
	for x in [-52.5, -6.0]:
		Build.cylinder(self, Vector3(x, 4.7, 112.0), 0.07, 9.0, metal)
		for height in [1.5, 4.5, 7.5]:
			Build.box(self, Vector3(x, height, 112.12), Vector3(0.25, 0.045, 0.2), metal)
	for index in range(5):
		var at := Vector3(-51.0 + index * 1.6, 0, 104.0)
		_place(PALLET, at)
		_place(CRATE, at + Vector3.UP * 0.23)
		if index % 2 == 0:
			_place(CRATE, at + Vector3.UP * 1.07)
	for z in [103.0, 105.5, 108.0]:
		_place(PALLET, Vector3(-7, 0, z))
	for x in [-48.0, -9.0]:
		Build.box(self, Vector3(x, 0.043, 107), Vector3(3.0, 0.015, 0.45), rubber)
		for index in range(14):
			Build.box(self, Vector3(x - 1.4 + index * 0.21, 0.055, 107),
				Vector3(0.045, 0.012, 0.43), metal)


func _place(scene: PackedScene, at: Vector3) -> void:
	var instance := scene.instantiate() as Node3D
	instance.position = at
	add_child(instance)
