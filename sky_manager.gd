extends Node3D

@export var day_material: ProceduralSkyMaterial
@export var sunset_material: ProceduralSkyMaterial
@export var night_material: ProceduralSkyMaterial
@export var world_environment: WorldEnvironment
@export var sun_light: DirectionalLight3D
@export var time_label: Label 

@export var day_speed := 0.3  # 控制時間流速（每秒多少小時）
var current_time := 3.0       # 初始為早上6點

@onready var world_env: WorldEnvironment = get_node("/root/Main/WorldEnvironment")

func set_fog(enabled: bool, density: float = 0.1, color: Color = Color(0.8, 0.8, 0.9)):
	var env: Environment = world_env.environment
	env.fog_enabled = enabled
	env.fog_sky_affect = false
	env.fog_density = density
	#env.fog_light_color = color
	env.fog_depth_begin = 0.0
	env.fog_depth_end = 50.0

func _ready():
	set_fog(true, 0.05, Color(0.5, 0.6, 0.7)) # 啟動較濃的白霧

func _process(delta: float) -> void:
	current_time += delta * day_speed
	if current_time >= 24.0:
		current_time -= 24.0

	update_sun_rotation()
	update_sky_material()
	update_time_display()

func update_sun_rotation():
	var angle = (current_time / 24.0) * 360.0
	sun_light.rotation.x = deg_to_rad(angle + 90.0)

func update_sky_material():
	var mat := ProceduralSkyMaterial.new()
	var env: Environment = world_env.environment
	# 漸變霧濃度 (0.0 ~ 0.05)
	var max_fog_density := 0.015
	var fog_density := 0.0
	
	if current_time < 4.5 or current_time >= 19.0:
		# 夜晚
		mat = night_material
		fog_density = 0.0
	elif current_time < 6.0:
		# 夜晚 → 白天（過渡）
		var t = (current_time - 4.5) / 1.5
		mat = _lerp_sky(night_material, day_material, t)
	elif current_time < 16.0:
		# 白天
		mat = day_material
		fog_density = max_fog_density
	elif current_time < 17.0:
		# 白天 → 黃昏（過渡）
		var t = (current_time - 16.0) / 1.0
		mat = _lerp_sky(day_material, sunset_material, t)
		fog_density = (17.0 - current_time) / 1.0 * max_fog_density
	elif current_time < 17.5:
		# 黃昏
		mat = sunset_material
		fog_density = 0.0
	elif current_time < 19.0:
		# 黃昏 → 夜晚（過渡）
		var t = (current_time - 17.5) / 1.5
		mat = _lerp_sky(sunset_material, night_material, t)
		fog_density = 0.0
	
	#霧(夜晚 -> 白天 過渡)
	if current_time > 5.0 and current_time < 6.0:
		fog_density = (current_time - 5.0) / 1.0 * max_fog_density
	
	set_fog(true, fog_density, Color(0.5, 0.6, 0.7))
	apply_sky(mat)

func apply_sky(mat: ProceduralSkyMaterial):
	var new_sky := Sky.new()
	new_sky.sky_material = mat
	world_environment.environment.sky = new_sky

func update_time_display():
	var hours := int(current_time) % 24
	var minutes := int((current_time - hours) * 60.0)
	var time_str := "%02d:%02d" % [hours, minutes]
	if time_label:
		time_label.text = "時間：" + time_str

func _lerp_color(a: Color, b: Color, t: float) -> Color:
	return Color(
		lerp(a.r, b.r, t),
		lerp(a.g, b.g, t),
		lerp(a.b, b.b, t),
		lerp(a.a, b.a, t)
	)

func _lerp_sky(a: ProceduralSkyMaterial, b: ProceduralSkyMaterial, t: float) -> ProceduralSkyMaterial:
	var result := ProceduralSkyMaterial.new()
	result.sky_top_color = _lerp_color(a.sky_top_color, b.sky_top_color, t)
	result.sky_horizon_color = _lerp_color(a.sky_horizon_color, b.sky_horizon_color, t)
	result.ground_bottom_color = _lerp_color(a.ground_bottom_color, b.ground_bottom_color, t)
	result.ground_horizon_color = _lerp_color(a.ground_horizon_color, b.ground_horizon_color, t)
	result.sun_angle_max = lerp(a.sun_angle_max, b.sun_angle_max, t)
	result.sun_curve = lerp(a.sun_curve, b.sun_curve, t)
	return result
