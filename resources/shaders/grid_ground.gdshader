shader_type spatial;
render_mode unshaded, cull_back;

// Grid ground shader for TANKS1990
// Provides visual grid lines for depth perception and navigation
// Unlit for performance and arcade aesthetic

uniform vec4 base_color : source_color = vec4(0.15, 0.15, 0.2, 1.0);
uniform vec4 grid_color : source_color = vec4(0.3, 0.3, 0.4, 1.0);
uniform float grid_scale : hint_range(0.1, 10.0) = 1.0;
uniform float grid_line_width : hint_range(0.01, 0.2) = 0.05;

void fragment() {
	// Get world position for grid calculation
	vec2 world_pos = UV * grid_scale * 26.0; // 26x26 grid
	
	// Calculate grid lines
	vec2 grid = abs(fract(world_pos - 0.5) - 0.5) / fwidth(world_pos);
	float line = min(grid.x, grid.y);
	
	// Apply grid pattern
	float grid_intensity = 1.0 - min(line, 1.0);
	vec3 final_color = mix(base_color.rgb, grid_color.rgb, grid_intensity * grid_line_width * 10.0);
	
	ALBEDO = final_color;
	ALPHA = 1.0;
}
