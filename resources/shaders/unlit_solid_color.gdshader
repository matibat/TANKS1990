shader_type spatial;
render_mode unshaded, cull_back;

// Unlit solid color shader for retro arcade aesthetic
// No lighting calculations - pure flat shading

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	ALBEDO = albedo_color.rgb;
	ALPHA = albedo_color.a;
}
