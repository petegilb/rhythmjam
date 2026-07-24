extends Control

@onready var main: RhythmMain = get_parent()
@onready var beat_visual = $BeatVisual

func song_beat_conn(last_beat):
	print(last_beat)
	beat_visual.visible = true
	await get_tree().create_timer(main.beat_duration_ms / 2).timeout
	beat_visual.visible = false

func _ready() -> void:
	beat_visual.visible = false
	main.song_beat.connect(song_beat_conn)
