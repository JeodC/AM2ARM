//
// Retro Palette Swapper — palette-lookup fragment shader.
// From PixelatedPope's Retro Palette Swapper, MIT License, (c) 2024 Pixelated Pope
// (https://github.com/PixelatedPope/RetroPaletteSwapper).
// Loop rewritten with a constant bound: strict GLSL ES compilers reject loops whose
// condition depends on a uniform, and the desktop original does exactly that.
//
#define Transparent vec4(0., 0., 0., 0.)
#define Tolerance 0.004
// Tallest shipped palette is 105 entries (monsters/alpha.png); bound must exceed it.
#define MaxPaletteHeight 128.

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D u_palTexture;
uniform vec4 u_Uvs;
uniform float u_paletteId;
uniform vec2 u_pixelSize;

vec4 findAltColor(vec4 inCol, vec2 corner)
{
    if (inCol.a == 0.) return Transparent;

    for (float i = 0.; i < MaxPaletteHeight; i += 1.)
    {
        float ty = corner.y + i * u_pixelSize.y;
        if (ty >= u_Uvs.w) break;

        vec4 leftCol = texture2D(u_palTexture, vec2(corner.x, ty));
        if (distance(leftCol, inCol) < Tolerance)
        {
            vec2 altPos = vec2(corner.x + u_pixelSize.x * floor(u_paletteId + 1.0), ty);
            return mix(texture2D(u_palTexture, vec2(altPos.x - u_pixelSize.x, altPos.y)),
                       texture2D(u_palTexture, altPos),
                       fract(u_paletteId));
        }
    }
    return inCol;
}

void main()
{
    vec4 col = texture2D(gm_BaseTexture, v_vTexcoord);
    DoAlphaTest(col);
    col = findAltColor(col, u_Uvs.xy);
    gl_FragColor = v_vColour * col;
}
