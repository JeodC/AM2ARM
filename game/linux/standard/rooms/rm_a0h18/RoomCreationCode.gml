// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 53;
global.mapoffsety = 34;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 1;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);

// Place the rescue-team artwork and its still-uncollected trooper-log trigger together.
tile_set_scale(tile_add(tlRescueTeam, 0, 0, 32, 32, 205, 624, 90), -1, 1);
create_log_trigger(true, 8, 184, 656, -25, true);