extends Node2D
class_name RhythmMain

signal song_beat(last_beat)

@onready var music_player = $MusicPlayer

var song1: AudioStream = preload("res://music/3.19 Sketch.mp3")
var bpm = 0
var beat_duration_ms = 0
var last_beat = 0
var next_beat_position = 0
var current_song_position: float = 0.0

# referenced this video: https://www.youtube.com/watch?v=9XcLoEVnjrA

func set_song(input_song: AudioStreamMP3) -> void:
	if not input_song:
		printerr("input song is invalid! can't set song")
		return
	music_player.stream = input_song
	bpm = input_song.bpm
# the higher the bpm, the shorter the beatDuration
# this is the time for quarter notes (can divide further for eight, sixteenth, etc.)
	beat_duration_ms = 60/bpm
	print("set song to %s with bpm %d and beat duration %f" % [input_song.resource_path, bpm, beat_duration_ms])
	
# start the selected song (restarts if already playing something)
func start_song():
	music_player.stop()
	if music_player.stream == null:
		printerr("music player has no song to play!")
		return
	last_beat = 0
	next_beat_position = beat_duration_ms
	music_player.play()
	
func update_song():
	current_song_position = music_player.get_playback_position()
	if current_song_position >= next_beat_position:
		last_beat += 1
		song_beat.emit(last_beat)
		next_beat_position += beat_duration_ms

func _ready() -> void:
	set_song(song1)
	start_song()

func _process(_delta: float) -> void:
	if music_player.is_playing():
		update_song()	
