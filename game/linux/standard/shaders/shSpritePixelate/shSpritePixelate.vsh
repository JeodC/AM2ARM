attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;

uniform vec4 uTextureUv;
uniform vec4 uDrawBounds;
varying highp vec2 vLocal;
varying vec4 vColour;

void main() {
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position, 1.0);
    // Primitive texture coordinates arrive mapped to this frame's atlas region.
    vec2 unit = (in_TextureCoord - uTextureUv.xy) / (uTextureUv.zw - uTextureUv.xy);
    vLocal = mix(uDrawBounds.xy, uDrawBounds.zw, unit);
    vColour = in_Colour;
}
