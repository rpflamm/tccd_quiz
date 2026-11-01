shader_type canvas_item;
// Animated background: dark gradient, soft drifting glow blobs, faint dot grid.

uniform vec4 base_color : source_color = vec4(0.063, 0.071, 0.102, 1.0);
uniform vec4 glow_a : source_color = vec4(1.0, 0.53, 0.0, 1.0);
uniform vec4 glow_b : source_color = vec4(0.30, 0.64, 1.0, 1.0);
uniform vec4 glow_c : source_color = vec4(0.65, 0.49, 1.0, 1.0);
uniform float intensity = 0.16;
uniform float speed = 0.05;
uniform vec2 resolution = vec2(1280.0, 720.0);
uniform float grid_size = 34.0;
uniform float energy = 0.0;   // 0..1, raised during streaks

float blob(vec2 uv, vec2 center, float radius) {
	float d = length(uv - center);
	return exp(-pow(d / radius, 2.0));
}

void fragment() {
	vec2 uv = UV;
	float aspect = resolution.x / resolution.y;
	vec2 p = vec2(uv.x * aspect, uv.y);
	float t = TIME * speed * (1.0 + energy * 3.0);

	vec2 ca = vec2(0.25 * aspect + 0.15 * sin(t * 3.1), 0.25 + 0.12 * cos(t * 2.3));
	vec2 cb = vec2(0.80 * aspect + 0.12 * cos(t * 2.7), 0.75 + 0.10 * sin(t * 1.9));
	vec2 cc = vec2(0.55 * aspect + 0.20 * sin(t * 1.7 + 1.3), 0.15 + 0.10 * cos(t * 2.9));

	vec3 col = base_color.rgb;
	float k = intensity * (1.0 + energy * 1.2);
	col += glow_a.rgb * blob(p, ca, 0.55) * k;
	col += glow_b.rgb * blob(p, cb, 0.60) * k * 0.8;
	col += glow_c.rgb * blob(p, cc, 0.45) * k * 0.6;

	// faint dot grid
	vec2 g = fract(uv * resolution / grid_size) - 0.5;
	float dotv = smoothstep(0.08, 0.0, length(g));
	col += vec3(dotv) * 0.035;

	// vignette
	float v = smoothstep(1.25, 0.35, length((uv - 0.5) * vec2(aspect, 1.0)));
	col *= mix(0.65, 1.0, v);

	COLOR = vec4(col, 1.0);
}
