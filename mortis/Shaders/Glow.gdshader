shader_type spatial;
render_mode cull_front, fog_disabled, specular_disabled, depth_draw_never;

void vertex() {
	VERTEX += NORMAL * 0.01;
}

void fragment() {

}

void light() {
	DIFFUSE_LIGHT = vec3(1.0);
}
