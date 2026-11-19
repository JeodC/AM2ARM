// Keep the first update under the runner's eligibility rules. A bubble
// created during Step may not receive that event until the following frame.
if (bubble_batch_frame == global.bubble_frame) exit;
if (bubble_batch_seen) {
    bubble_update_batch();
    exit;
}
bubble_batch_seen = true;
bubble_batch_frame = global.bubble_frame;

if (fadeout) {
    image_alpha -= 0.1;
    if (image_alpha <= 0) instance_destroy();
} else if (y < global.waterlevel + global.wateroffset + 10) fadeout = 1;
if (!eris) {
    if (hspeed != 0) hspeed *= 0.9;
    if (vspeed > -1) vspeed -= 0.02;
    if (vspeed > 2) vspeed = 2;
} else speed = lerp(speed, 0, 0.05);

// Camera bounds are shared until the next Begin Step or explicit view edit.
// Padding remains live because display settings can change during this step.
if (!global.bubble_view_ready) {
    var _camera = view_get_camera(0);
    var _left = camera_get_view_x(_camera), _top = camera_get_view_y(_camera);
    global.bubble_view_left = _left;
    global.bubble_view_right = _left + camera_get_view_width(_camera);
    global.bubble_view_top = _top;
    global.bubble_view_bottom = _top + camera_get_view_height(_camera);
    global.bubble_view_ready = true;
}
var _padding = oControl.widescreen_space / 2;
var _outside = x < global.bubble_view_left - _padding || x > global.bubble_view_right + _padding;
if (!_outside)
    _outside = y < global.bubble_view_top || y > global.bubble_view_bottom;
if (_outside) {
    visible = false;
    if (fps_real < 60) instance_destroy();
}
