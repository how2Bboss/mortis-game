shader_type spatial;

render_mode unshaded;
uniform sampler2D debugTex : filter_nearest_mipmap_anisotropic;
uniform vec3 color1 : source_color = vec3(1.0,0.0,1.0);
uniform vec3 color2 : source_color = vec3(0.0,0.0,0.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 newUV = UV + TIME*0.5;

	vec4 debugTex2 = texture(debugTex, newUV);
	float value = debugTex2.r;

	ALBEDO = mix(color1, color2, value);

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
