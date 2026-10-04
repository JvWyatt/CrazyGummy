shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

// Un único shader para las gomitas: sin texturas, lectura de pantalla ni bucles.
uniform vec4 primary_color : source_color = vec4(0.95, 0.08, 0.22, 1.0);
uniform vec4 secondary_color : source_color = vec4(1.0, 0.42, 0.55, 1.0);
uniform float opacity : hint_range(0.82, 1.0, 0.01) = 0.90;
uniform float surface_roughness : hint_range(0.05, 0.75, 0.01) = 0.18;
uniform float internal_glow : hint_range(0.0, 0.3, 0.01) = 0.10;
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
	// Absorción suave e iluminación interior simulada: volumen legible sin refraction.
	ALBEDO = tint * mix(0.83, 1.0, facing);
	METALLIC = 0.0;
	ROUGHNESS = roughness;
	SPECULAR = 0.65;
	RIM = 0.30;
	RIM_TINT = 0.65;
	EMISSION = tint * internal_glow * (0.45 + facing * 0.55);
	ALPHA = clamp(opacity + edge * 0.06, 0.82, 1.0);
}
