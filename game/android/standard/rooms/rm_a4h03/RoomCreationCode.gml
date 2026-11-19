// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 32;
global.mapoffsety = 27;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 3;
global.darkness = 0;

// Create the pickups selected by this game's item mapping.
instance_create(1120, 672, scr_itemsopen(oControl.mod_251));
instance_create(400, 64, scr_itemsopen(oControl.mod_257));

// Place the research-base artwork beside its still-uncollected trooper-log trigger.
tile_add(tlResearchBase, 48, 32, 32, 32, 1520, 592, 90);
create_log_trigger(true, 5, 1544, 624, -27, true);