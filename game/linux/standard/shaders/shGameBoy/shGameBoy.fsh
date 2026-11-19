//
// GameBoy display mode — original implementation for the Android port.
// The paid asset AM2R CU used ("GameBoy Shader" by PixHammer) is no longer
// sold anywhere, so this is a clean-room replacement written against the
// interface in set_8bit_shader(): four palette colors as RGB 0-255 uniforms,
// darkest to lightest. Each pixel of the finished frame is bucketed into one
// of the four shades by luminance, like a DMG LCD would.
// Thresholds tuned by side-by-side comparison with the PC reference build.
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec3 u_color1; // darkest
uniform vec3 u_color2;
uniform vec3 u_color3;
uniform vec3 u_color4; // lightest

void main()
{
    vec4 src = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
    float lum = dot(src.rgb, vec3(0.299, 0.587, 0.114));
    // Perceptual banding: without the gamma lift, this game's dark art lands
    // almost entirely in the bottom shade (unreadable pause screen, pitch-black
    // caves). Equal bands in gamma space match how the eye — and the original
    // hardware's art — distribute the four tones.
    lum = pow(lum, 0.4545);

    vec3 shade;
    if      (lum < 0.25) shade = u_color1;
    else if (lum < 0.50) shade = u_color2;
    else if (lum < 0.75) shade = u_color3;
    else                 shade = u_color4;

    gl_FragColor = vec4(shade / 255.0, src.a);
}
