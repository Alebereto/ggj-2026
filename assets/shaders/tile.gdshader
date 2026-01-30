shader_type spatial;
render_mode unshaded;

void vertex() {
	VERTEX += vec3(0,0,0);
}

void fragment() {
	ALBEDO = vec3(0.0,0.6,0.5);
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
