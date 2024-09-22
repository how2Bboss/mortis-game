shader_type spatial;

render_mode unshaded;
uniform vec3 col : source_color;
uniform float explode : hint_range(-0.1, 0.1, 0.01) = 0.0;
uniform float flip : hint_range(-1.0, 1.0, 1.0) = 1.0;

void vertex() {
	VERTEX += NORMAL * (explode + 1.0);
	VERTEX *= flip * 0.05;
}

void fragment() {
	ALBEDO = col;
	// Called for every pixel the material is visible on.
}
