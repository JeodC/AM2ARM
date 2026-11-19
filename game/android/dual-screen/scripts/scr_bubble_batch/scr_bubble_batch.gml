// The pinned runner dispatches eligible instances in object groups. Start
// this work from the first mature bubble's own Step, never from a new controller
// at a different point in the frame. New bubbles keep their original first Step.
// All existing instance identities, alarms, automatic motion and Draws survive.
function bubble_update_batch() {
    var _frame = global.bubble_frame;
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
    var _left = global.bubble_view_left - _padding;
    var _right = global.bubble_view_right + _padding;
    var _top = global.bubble_view_top, _bottom = global.bubble_view_bottom;
    var _surface = global.waterlevel + global.wateroffset + 10;
    var _discard = fps_real < 60;
    with (oLBubble) {
        if (!bubble_batch_seen || bubble_batch_frame == _frame) continue;
        bubble_batch_frame = _frame;
        if (fadeout) {
            image_alpha -= 0.1;
            if (image_alpha <= 0) instance_destroy();
        } else if (y < _surface) fadeout = 1;
        if (!eris) {
            if (hspeed != 0) hspeed *= 0.9;
            if (vspeed > -1) vspeed -= 0.02;
            if (vspeed > 2) vspeed = 2;
        } else speed = lerp(speed, 0, 0.05);
        if (x < _left || x > _right || y < _top || y > _bottom) {
            visible = false;
            if (_discard) instance_destroy();
        }
    }
}
