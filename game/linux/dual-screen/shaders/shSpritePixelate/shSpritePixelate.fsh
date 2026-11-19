#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#endif

varying highp vec2 vLocal;
varying vec4 vColour;
uniform vec4 uTextureUv;
uniform vec4 uSprite;
uniform vec4 uPixelScale;

void main() {
    // Sample the centre of each block directly from the sprite texture.
    vec2 samplePosition = (floor(vLocal / uPixelScale.xy) + 0.5) * uPixelScale.xy;
    vec2 sourcePixel = samplePosition * uPixelScale.zw - uSprite.xy;
    // Trimmed transparent margins must not sample neighbouring atlas sprites.
    vec2 inside = step(vec2(0.0), sourcePixel) * (vec2(1.0) - step(uSprite.zw, sourcePixel));
    vec2 pixelCentre = clamp(floor(sourcePixel) + 0.5, vec2(0.5), uSprite.zw - 0.5);
    vec2 uv = mix(uTextureUv.xy, uTextureUv.zw, pixelCentre / uSprite.zw);
    gl_FragColor = texture2D(gm_BaseTexture, uv) * vColour * inside.x * inside.y;
}
