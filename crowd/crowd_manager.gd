extends Node

@onready var crowd_parent = $"../crowd"
@onready var crowd_animator = $CrowdAnimator
@onready var camera: Camera3D = $"../Camera3D"
@onready var main: RhythmMain = $"../.."

const SHIRT_COLORS: Array[Color] = [
	Color(0.85, 0.24, 0.22),  # red
	Color(0.95, 0.55, 0.15),  # orange
	Color(0.96, 0.80, 0.25),  # mustard
	Color(0.35, 0.68, 0.32),  # green
	Color(0.18, 0.55, 0.72),  # teal
	Color(0.22, 0.33, 0.70),  # royal blue
	Color(0.55, 0.32, 0.68),  # purple
	Color(0.16, 0.17, 0.20),  # charcoal
	Color(0.45, 0.72, 0.75),  # pale cyan
	Color(0.72, 0.28, 0.42),  # raspberry
]

const PANTS_COLORS: Array[Color] = [
	Color(0.16, 0.22, 0.36),  # dark denim
	Color(0.28, 0.38, 0.55),  # mid denim
	Color(0.45, 0.55, 0.68),  # light wash
	Color(0.13, 0.13, 0.15),  # black
	Color(0.30, 0.30, 0.32),  # charcoal
	Color(0.52, 0.50, 0.46),  # grey
	Color(0.68, 0.60, 0.44),  # khaki
	Color(0.42, 0.34, 0.26),  # brown
	Color(0.34, 0.38, 0.30),  # olive
]

const CAP_COLORS: Array[Color] = [
	Color(0.10, 0.10, 0.12),  # black
	Color(0.30, 0.30, 0.32),  # charcoal
	Color(0.34, 0.38, 0.30),  # olive
	Color(0.16, 0.22, 0.36),  # dark denim
]

# referenced 
var SKIN_COLORS = [
	Color.from_rgba8(255, 229, 217),
	Color.from_rgba8(245, 208, 197),
	Color.from_rgba8(235, 196, 175),
	Color.from_rgba8(212, 165, 116),
	Color.from_rgba8(198, 134, 66),
	Color.from_rgba8(141, 85, 36),
	Color.html("#5C4033")
]
const SKIN_MAT_IDX = 0
const SHIRT_MAT_IDX = 1
const PANTS_MAT_IDX = 2
const CAP_MAT_IDX = 3
const HEAD_BONE_IDX = 1
const LHAND_BONE_IDX = 2
const RHAND_BONE_IDX = 3

# head bob, in radians of nod at the peak
const BOB_AMOUNT_MIN = 0.20
const BOB_AMOUNT_MAX = 0.40
# beats of jitter so the crowd isn't perfectly mechanical
const BOB_PHASE_JITTER = 0.1
# vertical body bounce in metres at the peak
const BOUNCE_MAX = 0.035

const SUCCESS_JUMP_HEIGHT_MIN = 0.05
const SUCCESS_JUMP_HEIGHT_MAX = 0.4
const SUCCESS_HAND_HEIGHT_MIN = 0.05
const SUCCESS_HAND_HEIGHT_MAX = 0.4

var crowd_members: Array = []
# per-member bob state, built in _ready so _process never has to get_node
var bobbers: Array[Dictionary] = []

func _ready() -> void:
	main.input_success.connect(input_success)
	
	# get all crowd members
	crowd_members = crowd_parent.get_children()
	
	# set the materials for each person
	for person: Node3D in crowd_members:
		var mesh: MeshInstance3D = person.get_node("mesh/Rig/Skeleton3D/Char1")
		mesh.set_instance_shader_parameter("skin_color", SKIN_COLORS.pick_random())
		
		# this is a standard material so we need to duplicate it unless we make it a shader mat
		var shirt_material: StandardMaterial3D = mesh.get_active_material(SHIRT_MAT_IDX).duplicate()
		shirt_material.albedo_color = SHIRT_COLORS.pick_random()
		mesh.set_surface_override_material(SHIRT_MAT_IDX, shirt_material)
		
		var pants_material: StandardMaterial3D = mesh.get_active_material(PANTS_MAT_IDX).duplicate()
		pants_material.albedo_color = PANTS_COLORS.pick_random()
		mesh.set_surface_override_material(PANTS_MAT_IDX, pants_material)
		
		var cap_material: StandardMaterial3D = mesh.get_active_material(CAP_MAT_IDX).duplicate()
		cap_material.albedo_color = CAP_COLORS.pick_random()
		mesh.set_surface_override_material(CAP_MAT_IDX, cap_material)
		
		# make the head face the camera
		var skeleton: Skeleton3D = person.get_node("mesh/Rig/Skeleton3D")		
		var pose := skeleton.get_bone_global_pose(HEAD_BONE_IDX)
		var local_target := skeleton.global_transform.affine_inverse() * camera.global_position
		var dir := (local_target - pose.origin).normalized()
		if dir.is_zero_approx():
			continue

		var b := Basis.looking_at(-dir, Vector3.UP)
		skeleton.set_bone_global_pose(HEAD_BONE_IDX, Transform3D(b, pose.origin))

		# cache what the bob needs
		bobbers.append({
			"skeleton": skeleton,
			"body": person,
			"look_basis": b,
			"head_origin": pose.origin,
			"rest_y": person.position.y,
			"phase": randf_range(-BOB_PHASE_JITTER, BOB_PHASE_JITTER),
			"amount": randf_range(BOB_AMOUNT_MIN, BOB_AMOUNT_MAX),
			"bounce": randf_range(0.0, BOUNCE_MAX),
		})

func _process(_delta: float) -> void:
	if main.beat_duration <= 0.0:
		return
	var beat_phase: float = main.current_song_position / main.beat_duration
	for bobber in bobbers:
		var time: float = fposmod(beat_phase + bobber.phase, 1.0)
		# 0 -> 1 -> 0 arch, so the head nods down on the beat and lifts back up
		# before the next one, instead of nodding up as far as it nods down
		var bob: float = sin(time * PI)
		var skeleton: Skeleton3D = bobber.skeleton
		skeleton.set_bone_global_pose(HEAD_BONE_IDX, Transform3D(
			bobber.look_basis * Basis(Vector3.RIGHT, bob * bobber.amount),
			bobber.head_origin))
		var body: Node3D = bobber.body
		body.position.y = bobber.rest_y - bob * bobber.bounce

func input_success() -> void:
	for bobber in bobbers:
		var body: Node3D = bobber.body
		var tween = get_tree().create_tween()
		var jump_y = bobber.rest_y + randf_range(SUCCESS_JUMP_HEIGHT_MIN, SUCCESS_JUMP_HEIGHT_MAX)
		tween.tween_property(body, "position:y", jump_y, main.beat_duration/2.0)
		tween.tween_property(body, "position:y", bobber.rest_y, main.beat_duration/2.0)
		
		#var skeleton: Skeleton3D = bobber.skeleton
		#var lhand_base: Transform3D = skeleton.get_bone_global_pose(LHAND_BONE_IDX)
		#var lhand_tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
		#lhand_tween.tween_property()
		
