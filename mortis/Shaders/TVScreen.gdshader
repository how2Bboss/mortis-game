shader_type spatial;

render_mode shadows_disabled;

uniform float distortion = 1.0;
uniform float aspect = 1.0;
uniform sampler2D effects;
uniform sampler2D screen : repeat_disable;
uniform sampler2D noise;
uniform float scale = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ROUGHNESS = 0.1;
	vec2 UV_Center = UV*2.0-1.0;
	UV_Center *= scale;
	vec2 xy = vec2(UV_Center.x * aspect, UV_Center.y);

	float d = pow(length(xy),distortion);
	xy = vec2(xy*d)/2.0+0.5;
	float a = length(xy*xy)*0.003;
	vec2 UVd = xy;
	float mul = texture(effects, UV*vec2(1.0,0.03)+vec2(0.0,TIME*0.015)).r;
	vec2 shift = vec2(mul*0.1, 0.0);
	float red = texture(screen, UVd+vec2(a,0.0)+shift).r;
	float green = texture(screen, UVd+shift).g;
	float blue = texture(screen, UVd+vec2(-a,0.0)+shift).b;

	vec2 uv_offset = (vec2(sin(TIME*0.1),cos(TIME*0.1))*1000.0);
	vec3 random = texture(noise, (UV*0.25) + uv_offset).rgb;
	float brightness = (red+green+blue)/3.0;
	vec3 col = vec3(red,green,blue);
	vec3 col2 = clamp(mix(1.0,0.0,(brightness*20.0)),0.0,1.0)*random*0.2;
	vec3 finalCol = mix(col,col2,0.1);


	ALBEDO = finalCol;

}
void light(){
	DIFFUSE_LIGHT = vec3(1.0);
}
