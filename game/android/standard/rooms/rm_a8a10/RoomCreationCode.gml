// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 44;
global.mapoffsety = 7;
global.floormaterial = 4;
global.waterlevel = 0;
global.darkness = 2;

// Create the trooper-log trigger only while that log is still uncollected.
create_log_trigger(true, 7, 675, 192, -16, true);