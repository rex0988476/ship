extends Node

@onready var sky_mat: ProceduralSkyMaterial = preload("res://sky_material.tres")

var current_top_color: Color
var current_horizon_color: Color
var target_top_color: Color
var target_horizon_color: Color
var transition_speed := 0.5  # 越大變化越快

func _ready():
	current_top_color = sky_mat.sky_top_color
	current_horizon_color = sky_mat.sky_horizon_color
	set_time("day")  # 預設白天

func _process(delta):
	# 線性插值 (Lerp) 過渡
	current_top_color = current_top_color.lerp(target_top_color, delta * transition_speed)
	current_horizon_color = current_horizon_color.lerp(target_horizon_color, delta * transition_speed)

	sky_mat.sky_top_color = current_top_color
	sky_mat.sky_horizon_color = current_horizon_color

# 可切換時間：day, dusk, night
func set_time(time_name: String):
	match time_name:
		"day":
			target_top_color = Color("#6FA5D6")
			target_horizon_color = Color("#B8C6D6")
		"dusk":
			target_top_color = Color("#F67E5C")
			target_horizon_color = Color("#926D91")
		"night":
			target_top_color = Color("#0A0F23")
			target_horizon_color = Color("#304050")
