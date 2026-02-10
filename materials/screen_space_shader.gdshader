shader_type spatial;
render_mode unshaded, skip_vertex_transform;
varying float depth;
uniform sampler2D screen_tex : hint_screen_texture;
uniform sampler2D depth_tex : hint_depth_texture;

#define FULLSCREEN

#ifdef FULLSCREEN
render_mode depth_test_disabled;
#endif

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233))) *
                 43758.5453123);
}

void vertex() {
	// Called for every vertex the material is visible on.
#ifdef FULLSCREEN
   	VERTEX = (INV_PROJECTION_MATRIX * vec4(VERTEX.xy,1.0,1.0)).xyz;
#else
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
    TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
#endif
}

void fragment() {
	
	ALBEDO = vec3(10.0*texture(depth_tex, SCREEN_UV).r, 0.0,0.0);
}

