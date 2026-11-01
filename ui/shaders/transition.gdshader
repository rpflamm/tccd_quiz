shader_type canvas_item;
// Diagonal two-colour wipe. progress 0..1 covers the screen, 1..2 uncovers it.

uniform float progress : hint_range(0.0, 2.0) = 0.0;
uniform vec4 color : source_color = vec4(1.0, 0.53, 0.0, 1.0);
uniform vec4 color_2 : source_color = vec4(0.06, 0.07, 0.1, 1.0);
uniform float slant = 0.35;

void fragment() {
	float d = UV.x + UV.y * slant;            // 0 .. 1 + slant
	float span = 1.0 + slant;
	float edge_in = progress * (span + 0.3);
	float edge_out = (progress - 1.0) * (span + 0.3);
	float covered_main = step(d, edge_in - 0.15);
	float covered_lead = step(d, edge_in);
	float uncovered = step(d, edge_out);
	vec4 c = mix(color, color_2, covered_main);
	float alpha = covered_lead * (1.0 - uncovered);
	if (progress > 1.0) {
		// leading accent stripe while uncovering
		float stripe = step(d, edge_out + 0.15) - uncovered;
		c = mix(color_2, color, stripe);
		alpha = 1.0 - uncovered;
	}
	COLOR = vec4(c.rgb, alpha);
}
