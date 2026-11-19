varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform sampler2D uLightTexture;
uniform vec3 uFlash;
uniform vec4 uLightUv;
uniform vec2 uOrigin;
void main() {
    vec4 mask = texture2D(gm_BaseTexture, v_vTexcoord);
    vec2 distance = abs(v_vTexcoord * uOrigin - uFlash.xy);
    vec2 quarter = clamp(vec2(1.0) - distance / 64.0, 0.0, 1.0);
    vec2 uv = mix(uLightUv.xy, uLightUv.zw, quarter);
    float inside = step(distance.x, 64.0) * step(distance.y, 64.0);
    vec4 lamp = texture2D(uLightTexture, uv);
    mask.rgb = max(vec3(0.0), mask.rgb - lamp.rgb * lamp.a * uFlash.z * inside);
    gl_FragColor = mask * v_vColour;
}
