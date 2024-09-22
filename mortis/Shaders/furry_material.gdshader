shader_type spatial;
render_mode depth_prepass_alpha, diffuse_lambert;
// render_mode alpha_to_coverage;// cull_disabled;//, depth_draw_always;//, alpha_to_coverage_and_one;
uniform float scale = 4.0;
group_uniforms strands;
uniform sampler2D fur_texture : hint_default_white;
uniform sampler2D grass_shell : filter_linear_mipmap_anisotropic;
uniform sampler2D grass_wind;
uniform sampler2D grass_color;
uniform float wind_strength : hint_range(0.0, 1.0, 0.1);

instance uniform float shell_depth;

void vertex(){
	vec3 wind = texture(grass_wind, UV*0.2 + TIME*0.004).rgb;
	VERTEX.xyz += (1.0/scale)*(vec3(wind.xyz * TANGENT) * 2.0 * wind_strength - (TANGENT * wind_strength)) * (shell_depth);
	//VERTEX.x += -0.4 * shell_depth/10.0;
	VERTEX += NORMAL * 0.01;

}

void fragment() {
	vec4 fur_tex = texture(fur_texture, UV*5.0*scale);
	vec4 col_tex = texture(grass_color, UV*0.22*scale);
	vec3 wind = texture(grass_wind, UV*0.3*scale + TIME*0.004).rgb;
	NORMAL_MAP = wind;
	NORMAL_MAP_DEPTH = wind_strength/2.0;
	ALPHA = texture(grass_shell, UV*20.0*scale).x;
	ALPHA_SCISSOR_THRESHOLD = mix(0.4,0.8,shell_depth);

	ALBEDO = fur_tex.rgb * mix(vec3(0.2), vec3(1.0), shell_depth*0.5) * col_tex.rgb;
	if (ALPHA < 0.1)
	{
		discard;
	}
}