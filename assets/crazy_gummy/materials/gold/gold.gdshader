shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 primary_color : source_color = vec4(1.0, 0.64, 0.08, 1.0);
uniform float surface_roughness : hint_range(0.05, 0.5, 0.01) = 0.18;
uniform float reflection_strength : hint_range(0.0, 1.5, 0.05) = 1.0;
uniform float reflection_fill : hint_range(0.0, 0.6, 0.01) = 0.30;

void fragment() {
	vec3 reflected = reflect(-normalize(VIEW), normalize(NORMAL));
	// Reflejo de softbox ligero para el entorno actual, que no tiene cielo/reflection probe.
	float band = smoothstep(-0.45, -0.22, reflected.y) * (1.0 - smoothstep(0.30, 0.52, reflected.y));
	float streak = pow(max(0.0, 1.0 - abs(reflected.x) * 1.4), 12.0);
	ALBEDO = primary_color.rgb;
	METALLIC = 1.0;
	ROUGHNESS = surface_roughness;
	SPECULAR = 0.8;
	EMISSION = primary_color.rgb * (reflection_fill + reflection_strength * (band * 0.65 + streak * 0.35));
	// Sin ALPHA: oro opaco, distinto del acabado translúcido de las gomitas.
}
