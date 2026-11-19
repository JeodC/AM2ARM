// Offset this room's local map cells into the world map.
global.mapoffsetx = 72;
global.mapoffsety = 43;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 1280, 0, 0, 0, 0, 1);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;

// Create the pickups selected by this game's item mapping.
instance_create(80, 176, scr_itemsopen(oControl.mod_302));