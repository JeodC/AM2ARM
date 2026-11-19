// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 42;
global.mapoffsety = 24;
global.watertype = 1;
global.floormaterial = 1;
global.darkness = 2;
// Schedule the environment scan if its log state permits it.
scan_log(4, get_text("ScanEvents", "ScanEnvironment"), 180, 1);
// Start the lab ambience only if that loop is not already playing.
if (!sfx_isplaying(musLabAmbience)) {
    mus_stop_all();
    mus_loop(musLabAmbience);
}