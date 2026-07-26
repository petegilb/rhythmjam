extends Control

@onready var main: RhythmMain = get_parent()
@onready var beat_visual = $GameUI/BeatVisual
@onready var win_screen = $CanvasLayer/WinScreen
@onready var lose_screen = $CanvasLayer/LoseScreen
@onready var bar: TextureProgressBar = $GameUI/Fuse
@onready var cursor = $GameUI/FuseCursor

var playback:AudioStreamPlaybackPolyphonic

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

func _update_cursor(_v) -> void:
	var local := Vector2(bar.size.x * bar.ratio, bar.size.y * 0.5)
	cursor.global_position = bar.get_global_transform() * local
	cursor.global_position += Vector2(0, -30)

func _ready() -> void:
	beat_visual.visible = false
	win_screen.visible = false
	lose_screen.visible = false
	bar.value_changed.connect(_update_cursor)
	_update_cursor(0.0)
	#main.song_beat.connect(song_beat_conn)
	#main.enter_beat.connect(input_range_start)
	#main.exit_beat.connect(input_range_stop)
	#main.input_success.connect(input_success)

# referenced: https://forum.godotengine.org/t/best-proper-way-to-do-ui-sounds-hover-click/39081/3
func _enter_tree() -> void:
	# Create an audio player
	var player = AudioStreamPlayer.new()
	add_child(player)

	# Create a polyphonic stream so we can play sounds directly from it
	var stream = AudioStreamPolyphonic.new()
	stream.polyphony = 32
	player.stream = stream
	player.play()
	# Get the polyphonic playback stream to play sounds
	playback = player.get_stream_playback()

	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node:Node) -> void:
	if node is Button:
		# If the added node is a button we connect to its mouse_entered and pressed signals
		# and play a sound
		node.mouse_entered.connect(_play_hover)
		node.pressed.connect(_play_pressed)

func _play_hover() -> void:
	playback.play_stream(preload("res://ui/RhythmGame Navigate.mp3"), 0, 0, randf_range(0.9, 1.1))

func _play_pressed() -> void:
	playback.play_stream(preload("res://ui/RhythmGame Select.mp3"), 0, 0, randf_range(0.9, 1.1))

func _on_play_again_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/main.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
