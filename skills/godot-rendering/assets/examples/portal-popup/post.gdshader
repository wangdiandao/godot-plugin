shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() { COLOR = vec4(vec3(1.0) - textureLod(screen_texture, SCREEN_UV, 0.0).rgb, 1.0); }
