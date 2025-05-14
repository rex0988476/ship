extends Node3D

@export var sensitivity := 0.01
var rotation_x := 0.0  # 上下角度

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# 左右旋轉（Yaw）
		rotate_y(-event.relative.x * sensitivity)
		# 上下旋轉（Pitch）
		rotation_x = clamp(rotation_x - event.relative.y * sensitivity, deg_to_rad(-80), deg_to_rad(30))
		$Camera3D.rotation.x = rotation_x
