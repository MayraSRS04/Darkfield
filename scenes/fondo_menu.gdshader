shader_type canvas_item;

uniform float velocidad : hint_range(0.0, 1.0) = 0.04;
uniform vec4 color_arena : source_color = vec4(0.18, 0.12, 0.05, 1.0);
uniform vec4 color_polvo : source_color = vec4(0.38, 0.26, 0.10, 1.0);
uniform vec4 color_calor : source_color = vec4(0.45, 0.28, 0.08, 0.4);

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido_suave(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = ruido(i);
	float b = ruido(i + vec2(1.0, 0.0));
	float c = ruido(i + vec2(0.0, 1.0));
	float d = ruido(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * velocidad;

	vec2 uv_polvo = uv * vec2(8.0, 3.0) + vec2(t * 0.6, t * 0.15);
	float polvo = ruido_suave(uv_polvo);
	polvo += ruido_suave(uv_polvo * 2.1 + vec2(0.4, 0.7)) * 0.5;
	polvo += ruido_suave(uv_polvo * 4.3 - vec2(0.2, 0.3)) * 0.25;
	polvo /= 1.75;

	float calor = sin(uv.x * 12.0 + t * 2.0 + ruido_suave(uv * vec2(3.0, 1.0)) * 4.0) * 0.5 + 0.5;
	calor *= smoothstep(0.6, 0.0, uv.y);
	calor *= 0.18;

	float vineta = uv.x * (1.0 - uv.x) * uv.y * (1.0 - uv.y) * 12.0;
	vineta = clamp(vineta, 0.0, 1.0);

	vec4 col = mix(color_arena, color_polvo, polvo * 0.65);
	col = mix(col, color_calor, calor);
	col.rgb *= 0.65 + 0.45 * vineta;
	COLOR = col;
}