if (sbeam == 1) {
    time += 0.4;
    w_arc = 40;
} else {
    time += 1;
    w_arc = 25;
    if (chargebeam == 1) w_arc = 30;
}
// Carry the shot with Samus's motion when she moves in its firing direction.
if (instance_exists(oCharacter)) {
    if ((maindir == 0 || maindir == 359.5 || maindir == 45 || maindir == 315) && oCharacter.xVel > 0) x += oCharacter.xVel;
    if ((maindir == 180 || maindir == 135 || maindir == 225) && oCharacter.xVel < 0) x += oCharacter.xVel;
    if (maindir == 270 && oCharacter.yVel > 0) y += oCharacter.yVel;
}
// Curve Wave shots around their original firing direction.
if (wbeam && sbeam == 0) {
    if (wbeamdir == 1) direction = maindir + w_arc * cos(time);
    if (wbeamdir == 0) direction = maindir - w_arc * cos(time);
}
// Fan the two outer Spazer shots outward, then bring them back toward the firing direction.
if (sbeam && wbeam == 0 && beamid == 1) {
    if (time < 1 && chargebeam == 0) direction = maindir + 20;
    if (time < 1 && chargebeam == 1) direction = maindir + 20;
    if (time >= 1.3 && direction > maindir && chargebeam == 0) direction -= 5;
    if (time >= 1 && direction > maindir && chargebeam == 1) direction -= 10;
}
if (sbeam && wbeam == 0 && beamid == 2) {
    if (time < 1 && chargebeam == 0) direction = maindir - 20;
    if (time < 1 && chargebeam == 1) direction = maindir - 20;
    if (maindir == 0) {
        maindir = 359.5;
        if (chargebeam == 1) y -= 1;
    }
    if (time >= 1.3 && direction < maindir && chargebeam == 0) direction += 5;
    if (time >= 1 && direction < maindir && chargebeam == 1) direction += 10;
}
if (sbeam && time > 2 && maindir == 359.5) direction = 0;
// Use wider opposing curves for the outer shots when Wave and Spazer are combined.
if (wbeam && sbeam) {
    if (beamid == 0 && chargebeam == 0) speed = 6.7;
    if (beamid == 0 && chargebeam == 1) speed = 9;
    if (beamid == 1) direction = maindir + 60 * cos(time);
    if (beamid == 2) direction = maindir - 60 * cos(time);
}
if (wbeam && pbeam) image_angle = direction;
if (chargebeam == 1 && sprite_index == sBeam2) {
    if (time < 1) image_xscale = 0.6;
    if (time > 1 && image_xscale < 1) image_xscale += 0.2;
}
// Add a small splash when the shot crosses the water level.
if (y > global.waterlevel && global.waterlevel != 0) {
    if (inwater == 0) instance_create(x, global.waterlevel, oSmallSplash);
    inwater = 1;
} else {
    if (inwater == 1) instance_create(x, global.waterlevel, oSmallSplash);
    inwater = 0;
}
// Resolve the live camera once within this event; retain the original bounds.
var _camera = view_get_camera(0);
var _left = camera_get_view_x(_camera);
var _padding = oControl.widescreen_space / 2;
var _outside = x < _left - 48 - _padding || x > _left + camera_get_view_width(_camera) + 48 + _padding;
if (!_outside) {
    var _top = camera_get_view_y(_camera);
    _outside = y < _top - 48 || y > _top + camera_get_view_height(_camera) + 48;
}
if (_outside) instance_destroy();
