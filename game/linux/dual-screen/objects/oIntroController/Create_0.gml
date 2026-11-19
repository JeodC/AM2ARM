alarm[0] = 180;
txt = get_text("Title", "ControllerRecommended");
// If on Linux, quickly toggle fullscreen to get rid of GM:S mess. Seemed to be the best place to do that.
if (os_type == os_linux && global.opfullscreen) {
    window_set_fullscreen(false);
    window_set_fullscreen(true);
}

