shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Caramelo opaco lacado, vetas de crema y fractura oscura. Sin reloj ni RNG.
uniform vec4 shell : source_color = vec4(0.42, 0.075, 0.14, 1.0);
uniform vec4 stripe : source_color = vec4(0.91, 0.64, 0.56, 1.0);
void fragment() {
	float wave = sin((UV.x * 5.0 + UV.y * 2.0) * 6.28318);
	float ribbon = smoothstep(0.0, 0.18, wave);
	float crack = 1.0 - smoothstep(0.012, 0.028, abs(UV.y - 0.5 - sin(UV.x * 18.84954) * 0.045));
	ALBEDO = mix(mix(shell.rgb, stripe.rgb, ribbon), vec3(0.09, 0.025, 0.055), crack);
	ROUGHNESS = 0.28 + crack * 0.45;
	SPECULAR = 0.6;
}
