extends Node

@onready var night_env: WorldEnvironment = get_node("/root/Main/WorldEnvironment")
@onready var day_env: WorldEnvironment = get_node("/root/Main/Day_environment")
@export var time_label: Label 
@export var day_speed := 0.3  # 控制時間流速（每秒多少小時）
var current_time := 16.0       # 初始為早上6點

func _ready():
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = load("res://sky_materials/NightSkyHDRI016B_4K-HDR.exr")

	var sky := Sky.new()
	sky.sky_material = pano

	var env: Environment = night_env.environment
	env.background_mode = 2
	env.sky = sky
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.05
	
func _process(delta: float) -> void:
	current_time += delta * day_speed
	if current_time >= 24.0:
		current_time -= 24.0
	
	update_time_display()
	update_sky_material()

func update_sky_material():
	var mat := ProceduralSkyMaterial.new()
	var night_env_env: Environment = night_env.environment
	var max_brightness = 1.0
	var min_brightness = 0.05
	if current_time < 4.5 or current_time >= 19.0:
		# 夜晚
		night_env_env.adjustment_brightness = min_brightness
	elif current_time < 6.0:
		# 夜晚 → 白天（過渡）
		var t = (current_time - 4.5) / 1.5
		night_env_env.adjustment_brightness = (max_brightness - min_brightness) * t + min_brightness
	elif current_time < 16.0:
		# 白天
		night_env_env.adjustment_brightness = max_brightness
	elif current_time < 17.0:
		# 白天 → 黃昏（過渡）
		var t = (current_time - 16.0) / 1.0
		night_env_env.adjustment_brightness = max_brightness
	elif current_time < 17.5:
		# 黃昏
		night_env_env.adjustment_brightness = max_brightness
	elif current_time < 19.0:
		# 黃昏 → 夜晚（過渡）
		var t = (current_time - 17.5) / 1.5
	
	# 夜晚亮度
	if current_time > 17.5 and current_time < 18.5:
		var t = (current_time - 17.5) / 1.0
		night_env_env.adjustment_brightness = max_brightness - (max_brightness - min_brightness) * t
	print(night_env_env.adjustment_brightness)

func update_time_display():
	var hours := int(current_time) % 24
	var minutes := int((current_time - hours) * 60.0)
	var time_str := "%02d:%02d" % [hours, minutes]
	if time_label:
		time_label.text = "時間：" + time_str
