extends RigidBody3D

@export var speed := 10.0 # 前進推力大小
@export var turn := 0.075 # 旋轉力矩大小
@export var buoyancy_force := 50.0    # 浮力強度
@export var damping := 2.0            # 垂直速度阻尼
@export var target_height := 1.8      # 希望船穩定在這個高度（通常 > 水面 Y）
var current_key := ""

@onready var wave_node: Node3D = $VisualWave         # 只拿來做 Wave 搖晃
@onready var ctrl_node: Node3D = $VisualWave/VisualCtrl
const ROLL_TORQUE   := 2.0                    # 轉彎時施加的扭矩
const ROLL_RETURN   := 3.0                    # 自動回正力
const SWAY_SPEED    := 0.8 # 波浪搖晃速度
const SWAY_AMOUNT   := 3.0 # 波浪搖晃幅度（°）

var sway_phase := 0.0                         # 波浪相位

const MAX_ROLL := 12.5          # 最大左右傾斜角（°） (最大允許傾斜角度（度）)
const ROLL_SPEED := 5.0        # 最快傾斜速度（°/s）
const SMOOTH_FACTOR := 8.0      # 內插平滑係數（愈大愈快貼近目標）

var target_roll := 0.0          #想要的 roll 值
var i =0
func _ready():
	# Godot 4.x 正確寫法
	axis_lock_angular_x = true   # 鎖定 X 轉動（Pitch）
	axis_lock_angular_z = true   # 鎖定 Z 轉動（Roll）
	
func _physics_process(delta):
	if get_parent().external_control_active:
		return
	# ─── 1. 波浪視覺搖晃（只動 Visual，與物理無關） ─────────────────(VisualWave)
	sway_phase += delta * SWAY_SPEED
	wave_node.rotation_degrees.x = sin(sway_phase) * SWAY_AMOUNT    # pitch 前後
	wave_node.rotation_degrees.z = cos(sway_phase) * SWAY_AMOUNT    # roll 左右
	# ─── 2. 推進 / 轉向（保持你原本邏輯） ─────────────────────────(VisualCtrl)
	if Input.is_action_pressed("ui_up"):
		apply_central_force(-transform.basis.z * speed)
	elif Input.is_action_pressed("ui_down"):
		apply_central_force(transform.basis.z * speed)
	if Input.is_action_pressed("ui_left"):# A（左轉）
		if ctrl_node.rotation_degrees.z <  MAX_ROLL:
			target_roll =  MAX_ROLL # 左傾
		else:
			target_roll = 0.0
		apply_torque(Vector3(0, 1, 0) * turn)
	elif Input.is_action_pressed("ui_right"):# D（右轉）
		if ctrl_node.rotation_degrees.z > -MAX_ROLL:
			target_roll = -MAX_ROLL # 右傾
		else:
			target_roll = 0.0
		apply_torque(Vector3(0, 1, 0) * -turn)
	# ─── 3. 自動回正「轉彎造成的傾斜」──────────────────────────────
	if !Input.is_action_pressed("ui_left") && !Input.is_action_pressed("ui_right"):
		target_roll = 0.0 # 回正
	# ─── 4. 以「距離目標角度」作為速度權重，達到漸進效果 ──(VisualCtrl)
	var current_roll := ctrl_node.rotation_degrees.z
	var diff := target_roll - current_roll         # 剩餘角度
	# 距離越大 → step 越大；距離趨近 0 → step 越小
	var step : float = clamp(abs(diff) / MAX_ROLL, 0.0, 1.0) * ROLL_SPEED * delta
	ctrl_node.rotation_degrees.z = move_toward(current_roll, target_roll, step)

	# 🌊 浮力控制（維持固定高度）
	var offset = target_height - global_transform.origin.y
	var float_force = Vector3.UP * buoyancy_force * offset
	apply_central_force(float_force)

	# 💧 垂直速度阻尼（避免彈跳）
	linear_velocity.y *= exp(-damping * delta)
	
	# 限制 Pitch（前後傾）和 Roll（左右傾）在 ±MAX_ROLL 度以內 (VisualCtrl)
	ctrl_node.rotation_degrees.x = 0 # clamp(rotation_degrees.x, -MAX_ROLL, MAX_ROLL)
	ctrl_node.rotation_degrees.z = clamp(ctrl_node.rotation_degrees.z, -MAX_ROLL, MAX_ROLL)
	
	#print(ctrl_node.rotation_degrees, target_roll)
	#print(wave_node.rotation_degrees)
