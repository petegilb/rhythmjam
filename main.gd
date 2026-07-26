extends Node2D
class_name RhythmMain

signal song_beat(last_beat)
signal enter_beat
signal exit_beat
signal input_success
signal input_miss
signal game_ended

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer1
@onready var end_music_player: AudioStreamPlayer = $EndMusicPlayer
@onready var level = $Level1
@onready var anim_player: AnimationPlayer = $Level1/AnimationPlayer
@onready var bomb_sfx: AudioStreamPlayer2D = $Level1/%BombSounds
@onready var ui = $Ui
@onready var ui_game = $Ui/GameUI
@onready var ui_rhythm = $Ui/GameUI/Exclamation
@onready var ui_rhythm_dest = $Ui/GameUI/ExclamationShape
@onready var ui_fuse: TextureProgressBar = $Ui/GameUI/Fuse
@onready var ui_win_screen = $Ui/CanvasLayer/WinScreen
@onready var ui_lose_screen = $Ui/CanvasLayer/LoseScreen
@onready var fuse_particle: GPUParticles3D = $Level1/turntable/record/bomb/FuseParticle

const UI_NOTE_SPEED = 1.0
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
var active_beat_position = -1
var spawn_idx = 0

# game state
var game_over = false
var num_success := 0
const WIN_PERCENTAGE = 0.7
var active_ui = {}
var fuse = 100.0
var fuse_speed = 1.0
var fuse_pause = 0.0
const MISS_PENALTY = 5.0
const HIT_PAUSE = 0.5

# sfx
var disappointment: AudioStreamMP3 = preload("res://music/RhythmGame Disappointment.mp3")
var one_two_three: AudioStreamMP3 = preload("res://music/RhythmGame 1,2,3 Go!.mp3")
var ok_sfx: AudioStreamMP3 = preload("res://music/RhythmGame Correct Input.mp3")
var miss_sfx: AudioStreamMP3 = preload("res://music/RhythmGame Incorrect Input.mp3")
var fall_sfx: AudioStream = preload("res://music/326133__wagna__falling.wav")
var explosion_sfx: AudioStream = preload("res://music/RhythmGame Explosion.mp3")
var evil_laugh_sfx: AudioStream = preload("res://music/evil_laugh.wav")
var woosh_sfx: AudioStream = preload("res://music/woosh.wav")
var spin_sfx: AudioStream = preload("res://music/400685__supersnd__fidget-spinner1.wav")

# referenced this video: https://www.youtube.com/watch?v=9XcLoEVnjrA

# scene refs
var record: Node3D
var bomb: Node3D
var beats_per_rotation: float = 4.0

func play_sfx(input_sfx: AudioStream, volume: float = 1.0):
	#sfx_player.stop()
	sfx_player.stream = input_sfx
	sfx_player.volume_linear = volume 
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
	spawn_idx = 0
	num_success = 0
	music_player.stream = input_song
	bpm = input_song.bpm
# the higher the bpm, the shorter the beatDuration
# this is the time for quarter notes (can divide further for eight, sixteenth, etc.)
	beat_duration = 60/bpm
	fuse_speed = 100.0 / input_song.get_length()
	
	# get the inputs from the chart created using https://alphros.itch.io/beatrice
	var notes = song_data.charts[0].notes
	for note in notes:
		var beat_float = float(note.beat)
		active_input_beats.append(beat_float)
		active_input_beats_sec.append(beat_float*beat_duration)
		
	print("set song to %s with bpm %d and beat duration %f with fuse speed %f" \
	 	% [input_song.resource_path, bpm, beat_duration, fuse_speed])
	print(active_input_beats_sec)
	
# start the selected song (restarts if already playing something)
func start_song():
	end_music_player.stop()
	music_player.stop()
	if music_player.stream == null:
		printerr("music player has no song to play!")
		return
	last_beat = 0
	next_beat_position = active_input_beats_sec[active_input_beat_idx]
	play_sfx(one_two_three)
	await sfx_player.finished
	music_player.play()
	anim_player.play("bombfly")
	play_sfx(fall_sfx, 0.3)
	bomb_sfx.play()
	music_player.finished.connect(song_ended)
	bomb.position += Vector3(0, 5, 0)
	bomb.visible = true
	
func update_song(delta: float):
	if fuse <= 0.0:
		music_player.stop()
		song_ended()
		return
	
	current_song_position = music_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	# Compensate for output latency. (https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html)
	current_song_position -= AudioServer.get_output_latency()
	while spawn_idx < active_input_beats_sec.size() \
			and current_song_position >= active_input_beats_sec[spawn_idx] - UI_NOTE_SPEED:
		var new_ui_note = ui_rhythm.duplicate()
		ui.add_child(new_ui_note)
		# TODO is this +1 correct?
		var idx = spawn_idx
		active_ui[idx] = new_ui_note
		var tween = get_tree().create_tween()
		var pos_diff = new_ui_note.position - ui_rhythm_dest.position
		var travel = active_input_beats_sec[idx] - current_song_position
		tween.tween_property(new_ui_note, "position", ui_rhythm_dest.position, travel)
		tween.tween_property(new_ui_note, "position", 
			ui_rhythm_dest.position - Vector2(pos_diff.x,0), travel)
		tween.tween_callback(func():
			new_ui_note.queue_free()
			active_ui.erase(idx)
		)
		spawn_idx += 1
	
	if current_song_position >= next_beat_position and current_song_position >= next_beat_position:
		last_beat += 1
		song_beat.emit(last_beat)
		active_input_beat_idx+=1
		if active_input_beat_idx < active_input_beats_sec.size():
			next_beat_position = active_input_beats_sec[active_input_beat_idx]
			print("next input set to %f" % next_beat_position)
		else:
			print("no more inputs!")
		
	if current_song_position >= next_beat_position - INPUT_MARGIN:
		if active_beat_position != next_beat_position:
			active_beat_position = next_beat_position
			enter_beat.emit()
	elif active_beat_position > -1 and current_song_position >= active_beat_position + INPUT_MARGIN:
		var hit_idx = active_input_beats_sec.find(active_beat_position)
		if active_ui[hit_idx].visible:
			play_sfx(disappointment)
			input_miss.emit()
			fuse -= MISS_PENALTY
		active_beat_position = -1
		exit_beat.emit()
		
	# update spinning record
	if record:
		var beats = current_song_position * (bpm / 60.0)
		var rotations = beats / beats_per_rotation
		record.rotation.y = -rotations * TAU
		
	# update fuse
	if fuse_pause <= 0.0:
		fuse -= fuse_speed * delta
		ui_fuse.value = fuse
		fuse_particle.emitting = true
	else:
		fuse_particle.emitting = false
		fuse_pause -= delta
		fuse_pause = clamp(fuse_pause, 0.0, HIT_PAUSE)
		if fuse_pause == 0.0:
			bomb_sfx.play()
	
	if Input.is_action_just_pressed("ui_left"):
		music_player.stop()
		song_ended()
	
	if Input.is_action_just_pressed("ui_right"):
		fuse = 0.0
	
	if Input.is_action_just_pressed("space"):
		if active_beat_position != -1:
			print("ok!")
			input_success.emit()
			play_sfx(ok_sfx, 0.5)
			num_success += 1
			var hit_idx = active_input_beats_sec.find(active_beat_position)
			if active_ui.has(hit_idx):
				active_ui[hit_idx].visible = false
				hit_pause()
		else:
			play_sfx(miss_sfx, 0.7)
			print("miss")
			fuse -= MISS_PENALTY

func song_ended() -> void:
	game_over = true
	bomb_sfx.stop()
	var total_beats: int = active_input_beats.size()
	var success_percentage = float(num_success) / float(total_beats)
	print("final percentage %f" % success_percentage)
	if fuse > 0.0:
		print("you win!")
		play_sfx(spin_sfx)
		var tween = get_tree().create_tween()
		tween.tween_property(record, "rotation:y", -TAU * 10, 1.0).as_relative()
		await tween.finished
		anim_player.play("win")
		play_sfx(woosh_sfx)
		await anim_player.animation_finished
		ui_win_screen.visible = true
		ui_game.visible = false
		end_music_player.play()
		game_ended.emit()
	else:
		record.rotation = Vector3(0, 0, 0)
		anim_player.play("EXPLODE")
		play_sfx(evil_laugh_sfx)
		print("you lose! the bomb exploded!")
		game_ended.emit()
		await anim_player.animation_finished
		ui_lose_screen.visible = true
		ui_game.visible = false
		play_sfx(explosion_sfx)

# if the player hits a note, pause the fuse momentarily.
func hit_pause() -> void:
	bomb_sfx.stop()
	fuse_pause = HIT_PAUSE

func _ready() -> void:
	# get record
	record = level.get_node("turntable/record")
	bomb = level.get_node("turntable/record/bomb")
	bomb.visible = false
	set_song(song1, song1_json_path)
	start_song()

func _process(delta: float) -> void:
	if music_player.is_playing() and not game_over:
		update_song(delta)
	
	#if we_won:
		#record.rotation.y = -rotations * TAU
