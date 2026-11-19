// Set world-map placement and liquid state.
global.mapoffsetx = 58;
global.mapoffsety = 13;
global.waterlevel = 0;
global.watertype = 0;

// Use item-room music when the optional music pack is available.
mus_change_itemroom();

// Create the pickups selected by this game's item mapping.
instance_create(24, 224, scr_itemsopen(oControl.mod_100));