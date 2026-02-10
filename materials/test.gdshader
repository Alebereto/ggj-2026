shader_type spatial;
render_mode unshaded, skip_vertex_transform;
render_mode depth_test_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

global uniform bool apply_screen_shader;
uniform float pixel_size : hint_range(1, 300, 0.5) = 1.0;




void vertex() {
	if(apply_screen_shader){
	   	VERTEX = (INV_PROJECTION_MATRIX * vec4(VERTEX.xy,1.0,1.0)).xyz;
	} else{
	    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	    BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
	    TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
	}
}
void fragment() {
	mat2 screen_ratio = mat2(vec2(VIEWPORT_SIZE.x/VIEWPORT_SIZE.y,0.0),vec2(0.0,1.0));
	mat2 screen_ratio_inverse = mat2(vec2(VIEWPORT_SIZE.y/VIEWPORT_SIZE.x,0.0),vec2(0.0,1.0));
	vec2 pixelated_uv = screen_ratio_inverse * (floor(SCREEN_UV * screen_ratio * pixel_size) + 0.5) / pixel_size;

	float depth_color = 10.0*texture(depth_tex, SCREEN_UV).r;
	vec3 color = texture(screen_tex, pixelated_uv).xyz;
	ALBEDO = color;
}

