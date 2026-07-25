extends Node2D
class_name RhythmMain

signal song_beat(last_beat)
signal enter_beat
signal exit_beat
signal input_success

@onready var music_player = $MusicPlayer
@onready var sfx_player = $SFXPlayer1

const INPUT_MARGIN = 0.08
var song1: AudioStreamMP3 = preload("res://music/DJ Track.mp3")
var song1_json_path = "res://music/export.json"
var bpm = 0
var active_input_beats = []
var active_input_beats_sec = []
var active_input_beat_idx = 0
# beat duration in seconds
var beat_duration = 0
var last_beat = 0
var next_beat_position = 0
var current_song_position: float = 0.0
var active_beat = -1

# sfx
var disappointment: AudioStreamMP3 = preload("res://music/RhythmGame Disappointment.mp3")
var one_two_three: AudioStreamMP3 = preload("res://music/RhythmGame 1,2,3 Go!.mp3")

# referenced this video: https://www.youtube.com/watch?v=9XcLoEVnjrA

func play_sfx(input_sfx: AudioStreamMP3):
	sfx_player.stop()
	sfx_player.stream = input_sfx
	sfx_player.play()

func set_song(input_song: AudioStreamMP3, song_path: String) -> void:
	if not input_song or input_song.bpm <= 0:
		printerr("input song is invalid! can't set song")
		return
	# get json file for song info
	var song_data_file = FileAccess.open(song_path, FileAccess.READ)
	if not song_data_file:
		printerr("song data file can't be opened, can't set song!")
		return
	var song_data = JSON.parse_string(song_data_file.get_as_text())
	if not song_data:
		print("song data json is invalid, can't set song!")
		return
	active_input_beats = []
	active_input_beats_sec = []
	active_input_beat_idx = 0
	music_player.stream = input_song
	bpm = input_song.bpm
# the higher the bpm, the shorter the beatDuration
# this is the time for quarter notes (can divide further for eight, sixteenth, etc.)
	beat_duration = 60/bpm
	
	# get the inputs from the chart created using https://alphros.itch.io/beatrice
	var notes = song_data.charts[0].notes
	for note in notes:
		var beat_float = float(note.beat)
		active_input_beats.append(beat_float)
		active_input_beats_sec.append(beat_float*beat_duration)
		
	print("set song to %s with bpm %d and beat duration %f" % [input_song.resource_path, bpm, beat_duration])
	print(active_input_beats_sec)
	
# start the selected song (restarts if already playing something)
func start_song():
	music_player.stop()
	if music_player.stream == null:
		printerr("music player has no song to play!")
		return
	last_beat = 0
	next_beat_position = active_input_beats_sec[active_input_beat_idx]
	play_sfx(one_two_three)
	await sfx_player.finished
	music_player.play()
	
func update_song():
	current_song_position = music_player.get_playback_position()
	if current_song_position >= next_beat_position:
		last_beat += 1
		song_beat.emit(last_beat)
		active_input_beat_idx+=1
		if active_input_beat_idx < active_input_beats_sec.size():
			next_beat_position = active_input_beats_sec[active_input_beat_idx]
			print("next input set to %f" % next_beat_position)
		else:
			print("no more inputs!")
		
	# TODO update this to the song beats (where to press button inputs)	
	if current_song_position >= next_beat_position - INPUT_MARGIN:
		if active_beat != next_beat_position:
			active_beat = next_beat_position
			enter_beat.emit()
	elif active_beat > -1 and current_song_position >= active_beat + INPUT_MARGIN:
		active_beat = -1
		exit_beat.emit()
	
	if Input.is_action_just_pressed("space"):
		if active_beat != -1:
			print("ok!")
			input_success.emit()
		else:
			play_sfx(disappointment)
			print("miss")

func _ready() -> void:
	set_song(song1, song1_json_path)
	start_song()

func _process(_delta: float) -> void:
	if music_player.is_playing():
		update_song()
