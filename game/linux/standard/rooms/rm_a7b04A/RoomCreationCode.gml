// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 7;
global.mapoffsety = 22;
global.waterlevel = 0;
global.floormaterial = 3;
// Choose the room music from the saved egg-encounter state.
if (global.event[302] == 0) {
    mus_change(musArea7A);
} else mus_change(musArea7C);

// After enough messages, create the remaining translation-log trigger and show its marker if a trigger exists.
if(oControl.chozomessage >= 10) {
    create_log_trigger(false, 44, 440, 111, 0, false);
    if (instance_exists(oLogTrigger)) {
        instance_create(438, 82, oChozoLogMarker);
        with(oLogTrigger) image_xscale = 2;
    }
}