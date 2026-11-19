// GameMaker prepends "precision mediump float;" on GLES targets. mediump is
// fp16 on mobile GPUs -- ~0.25-texel error at this surface size, which smears
// the sub-texel blend band this shader exists to place. Re-declare highp for
// everything below; guarded so museum-grade GPUs fall back instead of failing
// to compile.
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#endif

//
// Sharp-pixel upscale ("sharp bilinear") for non-integer scale factors.
//
// Plain nearest-neighbor at a fractional scale (e.g. 4.5x on a 1080p phone)
// renders some source pixels one screen-pixel taller/wider than others —
// visible sawtooth "teeth" along edges. This shader snaps sampling to texel
// centers so pixels stay crisp, but lets hardware bilinear blend across a
// single screen-pixel band at each texel edge, which absorbs the remainder.
// Requires linear texture filtering to be enabled for the draw call
// (see sharp_scale_begin in draw_game_surface).
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 u_texSize; // source surface size in texels
uniform float u_scale;  // screen pixels per texel

void main()
{
    vec2 pix = v_vTexcoord * u_texSize;
    vec2 seam = floor(pix + 0.5);
    pix = seam + clamp((pix - seam) * u_scale, -0.5, 0.5);
    gl_FragColor = v_vColour * texture2D(gm_BaseTexture, pix / u_texSize);
}
