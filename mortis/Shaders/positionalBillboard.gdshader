shader_type spatial;
render_mode depth_draw_opaque;
uniform sampler2D texture_albedo : filter_nearest_mipmap_anisotropic;
uniform sampler2D normal_map: filter_nearest_mipmap_anisotropic;
uniform sampler2D grad: filter_linear;
uniform vec4 transmission : source_color;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0);

uniform float distance_fade_min : hint_range(0.0, 4096.0, 0.01);
uniform float distance_fade_max : hint_range(0.0, 4096.0, 0.01);

void vertex() {
	vec3 dir = CAMERA_POSITION_WORLD - NODE_POSITION_WORLD;
	dir.y = 0.0;
	dir = normalize(dir);
	mat3 bt = mat3(cross(vec3(0.0,1.0,0.0),dir),vec3(0.0,1.0,0.0),dir);
	VERTEX = bt * VERTEX;
	NORMAL = dir;
}

void fragment() {
	vec4 tex = texture(texture_albedo, UV);
	if (tex.a < alpha_scissor_threshold) {
		discard;
	}
	vec4 tex2 = texture(normal_map, UV);
	NORMAL_MAP = tex2.rgb;
	NORMAL_MAP_DEPTH = 1.0;
	BACKLIGHT = transmission.rgb;
	ALBEDO = tex.rgb/2.0;
	ALBEDO *= texture(grad, UV).rgb;

	{
		// Distance Fade: Pixel Dither
		float fade_distance = length(VERTEX);

		// Use interleaved gradient noise, which is fast but still looks good.
		const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
		float fade = clamp(smoothstep(distance_fade_min, distance_fade_max, fade_distance), 0.0, 1.0);
		// Use a hard cap to prevent a few stray pixels from remaining when past the fade-out distance.
		if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
			discard;
		}
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
