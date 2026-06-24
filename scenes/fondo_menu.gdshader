shader_type canvas_item;

uniform float velocidad : hint_range(0.0, 1.0) = 0.08;
uniform vec4 color_linea : source_color = vec4(0.12, 0.28, 0.55, 1.0);
uniform vec4 color_fondo : source_color = vec4(0.03, 0.06, 0.12, 1.0);

void fragment() {
	vec2 uv = UV * vec2(6.0, 10.0);
	uv.y += TIME * velocidad;
	uv.x += sin(TIME * velocidad * 0.4 + UV.y * 3.0) * 0.3;
	float linea = abs(sin(uv.y * 3.14159));
	linea = smoothstep(0.92, 1.0, linea) * 0.4;
	float linea_v = abs(sin(uv.x * 3.14159));
	linea_v = smoothstep(0.94, 1.0, linea_v) * 0.2;
	COLOR = mix(color_fondo, color_linea, linea + linea_v);
}