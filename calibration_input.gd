extends SpinBox

func _ready() -> void:
	value = Global.audio_calibration
	value_changed.connect(_on_value_changed)
	# stop the text field from eating the "space" note input and typing a space
	get_line_edit().gui_input.connect(_on_line_edit_gui_input)

func _on_value_changed(new_value: float) -> void:
	Global.set_audio_calibration(new_value)

func _on_line_edit_gui_input(event: InputEvent) -> void:
	if event.is_action("space"):
		get_line_edit().accept_event()
