extends RigidBody3D

@export var sway_amount := 0.03
@export var sway_speed := 1.0

var sway_phase := 0.0

@export var water_level := 0.0          # 水面高度 (Y軸)
@export var buoyancy_force := 50.0     # 浮力大小
@export var damping := 2.0             # 垂直速度阻尼

@export var max_tilt_angle := 45.0  # 最大允許傾斜角度（度）
@export var upright_stiffness := 10.0    # 回正速度（彈力）
@export var upright_damping := 4      # 阻尼（減震）

@export var base_speed := 1.0
@export var speed_variation := 1.0
@export var turn_rate := 20.0 # 每秒最大轉向速度（radians）
@export var target_change_interval := Vector2(3.0, 6.0)

var current_speed := 0.0
var target_angle := 0.0 # 目標航向角（以 Y 軸旋轉）
var timer := 0.0
var next_change_time := 0.0

func _ready():
	randomize()
	#_pick_new_target()

func _physics_process(delta):
	# 1️⃣ 浮力控制：只在船低於水面時施加浮力
	var depth = water_level - global_transform.origin.y
	if depth > 0:
		var float_force = Vector3.UP * buoyancy_force * depth
		apply_central_force(float_force)
	
	# 2️⃣ 垂直速度阻尼，避免上下晃太大
	linear_velocity.y *= exp(-damping * delta)
	
	###撞到就翻倒code:
	# 偏轉方向：將 local 船體「上方向」與世界的 Y 軸做比較
	#var up_direction := -transform.basis.y
	#var correction_axis := up_direction.cross(Vector3.UP)  # 修正轉動方向
	#var tilt_amount := up_direction.angle_to(Vector3.UP)   # 與垂直的偏離角度
	##var tilt_ratio := tilt_amount / deg_to_rad(max_tilt_angle)
	##tilt_ratio = clamp(tilt_ratio, 0.0, 1.0)
	##var torque_factor := 1.0 - tilt_ratio
	# 溫和回正力矩（像不倒翁）
	##var torque := correction_axis.normalized() * tilt_amount * torque_factor * upright_stiffness
	#var torque := correction_axis.normalized() * tilt_amount * upright_stiffness
	#torque -= angular_velocity * upright_damping  # 線性阻尼
	#apply_torque(torque)
	###撞到就翻倒code end:
	
	# 1️⃣ 計算目前朝向與目標角度差
	var current_yaw = rotation.y
	var angle_diff = wrapf(target_angle - current_yaw, -PI, PI)	
	# 2️⃣ 根據差距施加 torque（控制轉向速度）
	var torque_strength = clamp(angle_diff, -1.0, 1.0) * turn_rate
	apply_torque(Vector3.UP * torque_strength)
	# 3️⃣ 加點角速度阻尼，避免轉過頭後一直轉
	#angular_velocity.y *= 0.9  # 可調成 0.9 更強阻尼
	sway_phase += delta * sway_speed
	var sway_x = sin(sway_phase) * sway_amount
	var sway_z = cos(sway_phase) * sway_amount

	var new_rot = rotation
	new_rot.x = sway_x
	new_rot.z = sway_z
	rotation = new_rot

	# 前進推力（沿著船的正面方向）
	var forward_dir = -transform.basis.z.normalized()
	apply_central_force(forward_dir * current_speed)
	# 計時更換目標方向與速度
	timer += delta
	#if timer >= next_change_time:
	#	_pick_new_target()

func _integrate_forces(state):
	# 鎖定翻覆（限制 X/Z 軸旋轉）
	var current_angular_velocity = state.get_angular_velocity()
	current_angular_velocity.x = 0
	current_angular_velocity.z = 0
	state.set_angular_velocity(current_angular_velocity)

func _pick_new_target(): #line 28, 77, 78
	# 設定新方向（目標角度）
	target_angle = randf_range(-PI, PI)
	# 設定新速度
	current_speed = base_speed + randf_range(-speed_variation, speed_variation)
	# 設定下次更換時間
	next_change_time = randf_range(target_change_interval.x, target_change_interval.y)
	timer = 0.0
