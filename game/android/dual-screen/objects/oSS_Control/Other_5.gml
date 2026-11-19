if (surface_exists(s_map)) surface_free(s_map);
// Restore the chosen gameplay aspect when leaving pause, then refresh the nearby minimap data.
if (oControl.thor_enabled) with (oControl) {
    widescreen = global.widescreen_enabled;
    widescreen_space = widescreen ? 106 : 0;
}
with (oControl) event_user(2);
