extends Node3D

@onready var pos_label := $CanvasLayer/Position_label
@onready var angle_rad_label := $CanvasLayer/Angle_label
@onready var speed_label := $CanvasLayer/Speed_label
@onready var angle_speed_label := $CanvasLayer/Angle_speed_label
@onready var test_label := $CanvasLayer/Test_label #line 65
#@onready var test_ship := get_node("17m_Torpedo_boat")
@onready var test_ship := get_node("Cargo_ship")
@onready var ship := $PlayerShip  # 如果不是直接子節點，請用相對路徑或 `get_node("...")`

#@onready var sun = $DirectionalLight3D
var time_of_day := 0.0  # 0 ~ 1 (0=清晨, 0.5=中午, 1=夜晚)

#@onready var speed_slider := $CanvasLayer/SpeedSlider
#@onready var turn_slider := $CanvasLayer/TurnSlider
#@onready var speed_name_label := $CanvasLayer/Speed_name_label
#@onready var turn_name_label := $CanvasLayer/Turn_name_label

var speed_unit = 5
var turn_unit = 3

#func _on_speed_slider_changed(value):
#	if value > 0:
#		ship.max_back_speed = 0
#		ship.max_forward_speed = value * speed_unit
#	elif value < 0:
#		ship.max_back_speed = -value * speed_unit
#		ship.max_forward_speed = 0
#	else:
#		ship.max_back_speed = 0
#		ship.max_forward_speed = 0
#	speed_name_label.text = "Speed: %d" % [value]

#func _on_turn_slider_changed(value):
#	if value > 0:
#		ship.max_left_turn = 0
#		ship.max_right_turn = value * turn_unit
#	elif value < 0:
#		ship.max_left_turn = -value * turn_unit
#		ship.max_right_turn = 0
#	else:
#		ship.max_left_turn = 0
#		ship.max_right_turn = 0
#	turn_name_label.text = "Turn: %d" % [value]

# 放你想載入的船場景路徑
var boat_scenes = [
	preload("res://ship_tscn/Old_boat.tscn"),
	preload("res://ship_tscn/Fishing_boat.tscn"),
	preload("res://ship_tscn/Cargo_ship.tscn"),
	preload("res://ship_tscn/17m_Torpedo_boat.tscn")
]
#var boat_start_pos = [
#	[0,0,50],
#	[0,0,-50],
#	[50,0,0],
#	[-50,0,0]
#]
var boat_start_pos = [
	[0,0,0],
	[200,0,0],
	[-200,0,0]
]
func _ready():
	pass
	#randomize()
	#var selected_scene = boat_scenes[randi() % boat_scenes.size()]
	#var boat_instance = selected_scene.istantiate()
	#var start_pos = boat_start_pos[randi() % boat_start_pos.size()]
	#boat_instance.position = Vector3(start_pos[0],start_pos[1],start_pos[2])  # 你可以自訂起始位置
	#boat_instance.position = Vector3(0,0,0)  # 你可以自訂起始位置
	#add_child(boat_instance)
	
	# 設定滑條屬性：中間為 0，範圍 -10 到 10
	#speed_slider.min_value = -10
	#speed_slider.max_value = 10
	#speed_slider.value = 0
	#speed_slider.step = 1
	#speed_slider.focus_mode = Control.FOCUS_NONE

	#turn_slider.min_value = -10
	#turn_slider.max_value = 10
	#turn_slider.value = 0
	#turn_slider.step = 1
	#turn_slider.focus_mode = Control.FOCUS_NONE
	#speed_slider.connect("value_changed", Callable(self, "_on_speed_slider_changed"))
	#turn_slider.connect("value_changed", Callable(self, "_on_turn_slider_changed"))

func _process(delta):
	var water = $Water
	var ship = $PlayerShip
	var mat: ShaderMaterial = water.get_active_material(0)

	if mat:
		# 給浮動水面用的時間參數
		mat.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)

		# 如果還在用遮蔽功能，也可以一起設
	#if ship:
	#	mat.set_shader_parameter("u_boat_position", ship.global_transform.origin)
	
	var pos = ship.global_transform.origin
	pos_label.text = "座標: X = %.1f, Z = %.1f" % [pos.x, pos.z]
	var horizontal_speed = Vector2(ship.linear_velocity.x, ship.linear_velocity.z).length()
	
	var angle_rad = ship.global_transform.basis.get_euler().y
	var heading = fposmod(rad_to_deg(angle_rad), 360.0)
	angle_rad_label.text = "朝向角度: %.1f 度" % [heading]
	# 1. 船艏向轉為單位向量
	var heading_rad = deg_to_rad(heading)# 角度轉為弧度
	var forward_vec = Vector2(-sin(heading_rad), -cos(heading_rad))# -Z軸朝北，X軸朝東
	# 2. 取當前水平速度向量
	var velocity_vec = Vector2(ship.linear_velocity.x, ship.linear_velocity.z)
	# 3. 計算點積（Dot Product）
	var dot = forward_vec.dot(velocity_vec)
	# 4. 判斷是否倒退
	var is_reversing = dot < 0
	if is_reversing:
		#speed_label.text = "速度: %.1f 節 倒退" % [horizontal_speed / speed_unit]
		speed_label.text = "速度: %.1f" % [horizontal_speed / speed_unit]
	else:
		#speed_label.text = "速度: %.1f 節" % [horizontal_speed / speed_unit]
		speed_label.text = "速度: %.1f" % [horizontal_speed / speed_unit]
	var rate_of_turn_deg = rad_to_deg(ship.angular_velocity.y)
	if rate_of_turn_deg == 0:
		angle_speed_label.text = "轉向率: 0.0 度/秒"
	else:
		angle_speed_label.text = "轉向率: %.1f 度/秒" % [-rate_of_turn_deg]
	
	pos = test_ship.global_transform.origin
	angle_rad = test_ship.global_transform.basis.get_euler().y
	rate_of_turn_deg = rad_to_deg(test_ship.angular_velocity.y)
	heading = fposmod(rad_to_deg(angle_rad), 360.0)
	horizontal_speed = Vector2(test_ship.linear_velocity.x, test_ship.linear_velocity.z).length()
	heading_rad = deg_to_rad(heading)# 角度轉為弧度
	forward_vec = Vector2(-sin(heading_rad), -cos(heading_rad))# -Z軸朝北，X軸朝東
	velocity_vec = Vector2(test_ship.linear_velocity.x, test_ship.linear_velocity.z)
	dot = forward_vec.dot(velocity_vec)
	is_reversing = dot < 0
	var speed_str = ""
	if is_reversing:
		#speed_str = "速度: %.1f 節 倒退" % [horizontal_speed / speed_unit]
		speed_str = "速度: %.1f" % [horizontal_speed / speed_unit]
	else:
		#speed_str = "速度: %.1f 節" % [horizontal_speed / speed_unit]
		speed_str = "速度: %.1f" % [horizontal_speed / speed_unit]
	if rate_of_turn_deg == 0:
		test_label.text = "其他船隻\n座標: X = %.1f, Z = %.1f\n%s\n轉向率: 0.0 度/秒\n朝向角度: %.1f 度" % [pos.x, pos.z, speed_str, heading]
	else:
		test_label.text = "其他船隻\n座標: X = %.1f, Z = %.1f\n%s\n轉向率: %.1f 度/秒\n朝向角度: %.1f 度" % [pos.x, pos.z, speed_str, -rate_of_turn_deg, heading]

	time_of_day += delta * 0.01  # 控制時間流逝速度
	time_of_day = fmod(time_of_day, 1.0)
	# 計算太陽角度（-90度到90度之間）
	#var angle = lerp(-90.0, 90.0, sin(time_of_day * PI))
	#sun.rotation_degrees.x = angle
