shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

// Un único shader para las gomitas: sin texturas, lectura de pantalla ni bucles.
uniform vec4 primary_color : source_color = vec4(0.9490196, 0.2196078, 0.2901961, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.1254902, 0.9019608, 0.7568627, 1.0);
uniform float opacity : hint_range(0.55, 0.95, 0.01) = 0.80;
uniform float surface_roughness : hint_range(0.08, 0.65, 0.01) = 0.16;
uniform float specular_strength : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float rim_strength : hint_range(0.0, 0.5, 0.01) = 0.18;
uniform float edge_opacity : hint_range(0.0, 0.25, 0.01) = 0.16;
uniform float volume_contrast : hint_range(0.0, 0.3, 0.01) = 0.12;
uniform int pattern_mode : hint_range(0, 4, 1) = 0;
uniform float pattern_scale : hint_range(1.0, 32.0, 0.5) = 12.0;
uniform float pattern_mix : hint_range(0.0, 1.0, 0.05) = 0.75;
uniform float sugar_amount : hint_range(0.0, 1.0, 0.05) = 0.0;
uniform float sugar_scale : hint_range(12.0, 70.0, 1.0) = 38.0;

varying vec3 candy_position;

void vertex() {
	// Coordenadas del modelo original: el squash/stretch permanece en su nodo.
	candy_position = VERTEX;
}

float grain_hash(vec3 cell) {
	return fract(sin(dot(cell, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void fragment() {
	vec3 tint = primary_color.rgb;
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float edge = pow(1.0 - facing, 3.0);
	float blend = 0.0;
	if (pattern_mode == 1) {
		blend = smoothstep(0.08, 0.90, candy_position.y);
	} else if (pattern_mode == 2) {
		float ribbon = sin((candy_position.y + candy_position.x * 0.35) * pattern_scale);
		blend = smoothstep(-0.25, 0.25, ribbon);
	} else if (pattern_mode == 3) {
		float vein = sin((candy_position.x + candy_position.y) * pattern_scale
			+ sin(candy_position.z * 9.0) * 2.0 + sin(candy_position.y * 7.0) * 2.0);
		blend = smoothstep(0.35, 0.95, vein);
	} else if (pattern_mode == 4) {
		// Nácar/iridiscencia estilizados: cambia con la luz, no con una animación idle.
		blend = pow(1.0 - facing, 0.7);
	}
	tint = mix(tint, secondary_color.rgb, blend * pattern_mix);
	float roughness = surface_roughness;
	if (sugar_amount > 0.0) {
		float grain = grain_hash(floor(candy_position * sugar_scale));
		float sugar = smoothstep(0.58, 0.90, grain) * sugar_amount;
		tint = mix(tint, vec3(1.0, 0.97, 0.93), sugar * 0.62);
		roughness = mix(roughness, 0.72, sugar);
		NORMAL = normalize(NORMAL + vec3(grain - 0.5, fract(grain * 7.0) - 0.5, 0.0) * sugar_amount * 0.12);
	}
	// Color saturado y bordes más densos: gelatina sólida, sin refracción ni emisión.
	ALBEDO = tint * mix(1.0 - volume_contrast, 1.0, facing);
	METALLIC = 0.0;
	ROUGHNESS = roughness;
	SPECULAR = specular_strength;
	RIM = rim_strength;
	RIM_TINT = 0.45;
	ALPHA = clamp(opacity + edge * edge_opacity, 0.55, 0.95);
}
