shader_type spatial;

// --- Skin base ---
uniform vec4 skin_color : source_color = vec4(1.0, 0.8, 0.7, 1.0);

// --- Face decal texture (RGBA, alpha = mask) ---
uniform sampler2D face_tex : source_color, filter_linear_mipmap, hint_default_transparent;
uniform vec2 face_uv_scale = vec2(1.0, 1.0);
uniform vec2 face_uv_offset = vec2(0.0, 0.0);
uniform float face_opacity : hint_range(0.0, 1.0) = 1.0;

// --- PBR params ---
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.5;

// --- Optional maps (leave empty to ignore) ---
uniform sampler2D normal_tex : hint_normal;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform bool use_normal_map = false;

void fragment() {
	vec2 face_uv = UV * face_uv_scale + face_uv_offset;
	vec4 face = texture(face_tex, face_uv);

	// Blend face over the flat skin color using the texture's alpha
	ALBEDO = mix(skin_color.rgb, face.rgb, face.a * face_opacity);

	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;

	if (use_normal_map) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
}