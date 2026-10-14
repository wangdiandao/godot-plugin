shader_type canvas_item;
uniform int stage = 2;
uniform float phase = 0.0;
void fragment() {
    float d = distance(UV, vec2(0.5));
    float mask = 1.0 - smoothstep(0.28, 0.32, d);
    float ring = mask * smoothstep(0.16, 0.22, d);
    vec3 portal = vec3(0.1 + 0.15 * sin(phase), 0.4, 0.8) * mask + vec3(0.2) * ring;
    COLOR = vec4(stage == 0 ? vec3(d) : (stage == 1 ? vec3(mask) : portal), 1.0);
}
