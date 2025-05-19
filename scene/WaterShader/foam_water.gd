extends Node3D

var timer: float
var distance: float = 7
var cameraLookAt: Vector3 = Vector3(0,0,0)

@onready var water: MeshInstance3D = $Water

func _input(event: InputEvent):
	if event.is_action("ui_cancel") and OS.get_name() != "Web":
		get_tree().quit()

func _physics_process(delta):
	timer += delta
	
func setFromSpherical(azimuthalAngle: float, polarAngle: float) -> Vector3:
	var cosPolar: float = cos(polarAngle)
	var sinPolar: float = sin(polarAngle)
	var cosAzim: float = cos(azimuthalAngle)
	var sinAzim: float = sin(azimuthalAngle)
	return Vector3(cosAzim * sinPolar, sinAzim * sinPolar, cosPolar)

func _on_check_box_toggled(toggled_on: bool) -> void:
	var water_mat: Material = water.get_surface_override_material(0)
	water_mat.set_shader_parameter("pixelate", toggled_on)
