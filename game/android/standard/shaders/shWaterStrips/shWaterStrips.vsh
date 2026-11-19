attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
uniform vec4 uOffsets[60];
uniform vec2 uOffset;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
void main() {
    float row = floor(in_Colour.r * 255.0 + 0.5);
    vec4 offsets = uOffsets[int(floor(row / 4.0))];
    float lane = mod(row, 4.0);
    float left = lane < 0.5 ? offsets.x : (lane < 1.5 ? offsets.y : (lane < 2.5 ? offsets.z : offsets.w));
    vec2 position = vec2(in_Position.x + left, in_Position.y + uOffset.y);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(position, 0.0, 1.0);
    v_vTexcoord = in_TextureCoord;
    v_vColour = vec4(1.0, 1.0, 1.0, in_Colour.a);
}
