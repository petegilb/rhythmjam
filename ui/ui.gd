extends Control

@onready var main: RhythmMain = get_parent()
@onready var beat_visual = $BeatVisual

func song_beat_conn(last_beat):
	print(last_beat)
	#beat_visual.visible = true
	#await get_tree().create_timer(main.beat_duration_ms / 2).timeout
	#beat_visual.visible = false

func input_range_start():
	beat_visual.visible = true
	return
	
func input_range_stop():
	beat_visual.color = Color(0.843, 0.239, 0.173)
	beat_visual.visible = false
	return
	
func input_success():
	beat_visual.color = Color(0.0, 0.953, 0.0, 1.0)
	return

func _ready() -> void:
	beat_visual.visible = false
	main.song_beat.connect(song_beat_conn)
	main.enter_beat.connect(input_range_start)
	main.exit_beat.connect(input_range_stop)
	main.input_success.connect(input_success)
