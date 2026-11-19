// Keep recent positions for the Speed Booster afterimages drawn from Samus' current surface.
for (var _trail_index = 10; _trail_index > 0; --_trail_index) {
    sx[_trail_index] = sx[_trail_index - 1];
}
sx[0] = x;
for (var _trail_index = 10; _trail_index > 0; --_trail_index) {
    sy[_trail_index] = sy[_trail_index - 1];
}
sy[0] = y;
// Cycle which afterimage is brightest to make the trail flicker.
if (fx == 0) {
    alpha1 = 0.8;
    alpha2 = 0.6;
    alpha3 = 0.4;
    alpha4 = 0.2;
}
if (fx == 1) {
    alpha1 = 0.2;
    alpha2 = 0.8;
    alpha3 = 0.6;
    alpha4 = 0.4;
}
if (fx == 2) {
    alpha1 = 0.4;
    alpha2 = 0.2;
    alpha3 = 0.8;
    alpha4 = 0.6;
}
if (fx == 3) {
    alpha1 = 0.6;
    alpha2 = 0.4;
    alpha3 = 0.2;
    alpha4 = 0.8;
}
fx += 1;
if (fx > 3) fx = 0;
x = oCharacter.x;
y = oCharacter.y;
if (global.currentsuit == 2) image_blend = make_color_rgb(165, 66, 181);
if (oCharacter.dash == 0 && oCharacter.charge == 0 && (oCharacter.state != 28 && oCharacter.state != 29 && oCharacter.state != 30 || oCharacter.state == 31 && oCharacter.statetime >= 10)) instance_destroy();

