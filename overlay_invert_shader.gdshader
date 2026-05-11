shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

//render_mode world_vertex_coords;

varying vec2 world_pos;
varying flat mat4 world_to_screen;

void vertex() {
	// Called for every vertex the material is visible on.
	world_to_screen = SCREEN_MATRIX * CANVAS_MATRIX;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	//world_pos = vec4(VERTEX, 0.0, 1.0);

}

float gray(vec3 x) {
	return (x.r + x.g + x.b) / 3.0;
}

void fragment() {
	vec2 tile_center = floor(world_pos.xy / 32.0) * 32.0 + 16.0;
	
	vec2 tile_center_screen = (world_to_screen * vec4(tile_center, 0, 1)).xy;
	tile_center_screen = tile_center_screen * 0.5 + 0.5;
	
	// Called for every pixel the material is visible on.
	vec4 tex = texture(TEXTURE, UV);
	
	vec4 screen = textureLod(screen_texture, SCREEN_UV, 2.0);

	COLOR = tex;
	if (gray(screen.rgb) < 0.5) {
		COLOR.rgb = 1.0 - tex.rgb;
	}

}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
