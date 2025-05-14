extends Control

@export var active_color := Color(1, 1, 0)   # 黃色
@export var default_color := Color(0.2, 0.2, 0.2)  # 深灰色

func _process(delta):
	update_key("ui_up", $W_label)
	update_key("ui_left", $A_label)
	update_key("ui_down", $S_label)
	update_key("ui_right", $D_label)

func update_key(action_name: String, label: Label):
	var is_pressed := Input.is_action_pressed(action_name)

	# 取得 StyleBoxFlat，如果尚未設定就建立一個
	var bg := label.get_theme_stylebox("normal") as StyleBoxFlat
	if bg == null:
		bg = StyleBoxFlat.new()
		label.add_theme_stylebox_override("normal", bg)

	# 改變背景顏色
	bg.bg_color = active_color if is_pressed else default_color
	# 設定文字顏色
	label.add_theme_color_override("font_color", Color.BLACK if is_pressed else Color.WHITE)
