if (!active) exit;
if (!instance_exists(owner)) { instance_destroy(); exit; }
if (wait_frames > 0) { --wait_frames; exit; }
var _move = 0;
if (oControl.kDown && (oControl.kDownPushedSteps == 0 || (oControl.kDownPushedSteps > 18 && oControl.kDownPushedSteps mod 5 == 0))) _move = 1;
if (oControl.kUp && (oControl.kUpPushedSteps == 0 || (oControl.kUpPushedSteps > 18 && oControl.kUpPushedSteps mod 5 == 0))) _move = -1;
if (oControl.kRight && oControl.kRightPushedSteps == 0) _move = page_rows;
if (oControl.kLeft && oControl.kLeftPushedSteps == 0) _move = -page_rows;
if (_move != 0) {
    selected = clamp(selected + _move, 0, array_length(entries) - 1);
    scroll = clamp(scroll, max(0, selected - page_rows + 1), selected);
    sfx_play(sndMenuMove);
}
if (oControl.kMenu2 && oControl.kMenu2PushedSteps == 0) {
    sfx_play(sndMenuCancel);
    instance_destroy();
    exit;
}
if (oControl.kMenu1 && oControl.kMenu1PushedSteps == 0) {
    sfx_play(sndMenuSel);
    folder_accept();
}
