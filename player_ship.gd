extends RigidBody3D

@export var sway_amount := 0.03
@export var sway_speed := 1.0

var sway_phase := 0.0

@export var speed := 10.0             # 前進推力大小
@export var turn := 20.0               # 旋轉力矩大小
@export var max_forward_speed := 0.0             # 前進推力大小
@export var max_back_speed := 0.0             # 後退推力大小
@export var max_right_turn := 0.0               # 右旋轉力矩大小
@export var max_left_turn := 0.0               # 左旋轉力矩大小
@export var buoyancy_force := 50.0    # 浮力強度
@export var damping := 2.0            # 垂直速度阻尼
@export var target_height := 1.8      # 希望船穩定在這個高度（通常 > 水面 Y）
var current_key := ""
@export var max_tilt_angle := 15.0  # 最大允許傾斜角度（度）

func _physics_process(delta):
	# 🚀 移動控制（WASD）
	if Input.is_action_pressed("ui_up"):# W（前進）
		if abs(linear_velocity.x) < max_forward_speed and abs(linear_velocity.z) < max_forward_speed:
			apply_central_force(-transform.basis.z * speed)
	if Input.is_action_pressed("ui_left"):# A（左轉）
		#print(abs(rad_to_deg(angular_velocity.y)),max_left_turn)
		if abs(rad_to_deg(angular_velocity.y)) < max_left_turn:
			apply_torque(Vector3.UP * turn)
	if Input.is_action_pressed("ui_right"):# D（右轉）
		#print(abs(rad_to_deg(angular_velocity.y)),max_right_turn)
		if abs(rad_to_deg(angular_velocity.y)) < max_right_turn:
			apply_torque(Vector3.UP * -turn)
	if Input.is_action_pressed("ui_down"):# S（後退）
		if abs(linear_velocity.x) < max_back_speed and abs(linear_velocity.z) < max_back_speed:
			apply_central_force(transform.basis.z * speed)
	#print(linear_velocity)
	#print(angular_velocity.y, max_right_turn)
	
	#模擬隨波浪搖晃
	sway_phase += delta * sway_speed
	var sway_x = sin(sway_phase) * sway_amount
	var sway_z = cos(sway_phase) * sway_amount

	var new_rot = rotation
	new_rot.x = sway_x
	new_rot.z = sway_z
	rotation = new_rot

	# 🌊 浮力控制（維持固定高度）
	var offset = target_height - global_transform.origin.y
	var float_force = Vector3.UP * buoyancy_force * offset
	apply_central_force(float_force)

	# 💧 垂直速度阻尼（避免彈跳）
	linear_velocity.y *= exp(-damping * delta)
	# 🚫 加入水平方向的線性阻力（讓移動不滑行）
	#linear_velocity.x *= 0.98  # 阻力係數（可微調）
	#linear_velocity.z *= 0.98
	# 🚫 加入角速度阻力（讓轉彎後不一直轉）
	#angular_velocity *= 0.95
	
	# 限制船的姿態傾斜（讓它只在 X/Z 軸微微傾斜）
	var euler = rotation_degrees
	# 限制 Pitch（前後傾）和 Roll（左右傾）在 ±max_tilt_angle 度以內
	euler.x = clamp(euler.x, -max_tilt_angle, max_tilt_angle)
	euler.z = clamp(euler.z, -max_tilt_angle, max_tilt_angle)
	rotation_degrees = euler
	
func _integrate_forces(state):
	# 鎖定翻覆（限制 X/Z 軸旋轉）
	var current_angular_velocity = state.get_angular_velocity()
	current_angular_velocity.x = 0
	current_angular_velocity.z = 0
	state.set_angular_velocity(current_angular_velocity)

#func _input(event):
#	if event is InputEventKey:
#		# 按下
#		if event.pressed:
#			match event.keycode:
#				KEY_W:
#					if current_key != "W":
#						print("正在按：W（前進）")
#						current_key = "W"
#				KEY_S:
#					if current_key != "S":
#						print("正在按：S（後退）")
#						current_key = "S"
#				KEY_A:
#					if current_key != "A":
#						print("正在按：A（左轉）")
#						current_key = "A"
#				KEY_D:
#					if current_key != "D":
#						print("正在按：D（右轉）")
#						current_key = "D"
#		# 放開（鬆鍵）
#		else:
#			if event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
#				print("（已放開）")
#				current_key = ""
