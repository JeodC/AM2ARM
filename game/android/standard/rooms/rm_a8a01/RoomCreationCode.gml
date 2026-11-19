// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 50;
global.mapoffsety = 7;
global.floormaterial = 4;
global.waterlevel = 0;
global.darkness = 2;

// Place the rescue-team artwork with its still-uncollected trooper-log trigger.
tile_add(tlRescueTeam, 0, 80, 64, 16, 152, 176, 90);
create_log_trigger(true, 6, 186, 192, -11, true);