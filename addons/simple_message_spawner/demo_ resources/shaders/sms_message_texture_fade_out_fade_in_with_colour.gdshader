shader_type canvas_item;

uniform sampler2D target_texture: filter_nearest;
uniform float weight: hint_range(0.0, 1.0);
uniform vec4 target_colour;

void fragment()
{	
	vec4 color_a = texture(TEXTURE, UV);
    vec4 color_b = texture(target_texture, UV) * (target_colour * weight);
    COLOR = mix(color_a, color_b, weight);    
}