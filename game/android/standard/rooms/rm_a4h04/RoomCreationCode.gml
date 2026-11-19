// Offset this room's local map cells into the world map.
global.mapoffsetx = 31;
global.mapoffsety = 30;
// Restore the lava and remaining scenery for the saved drainage stage.
if (global.lavastate <= 6) {
    make_liquid(1, 2864, 0, 0, 0, 0, 1);
} else tile_layer_delete(-90);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;
// Set the darkness level consumed by room lighting setup.
global.darkness = 0;
// Choose the room music from the saved facility power-switch state.
if (global.event[200] == 0) {
    mus_change(musCaveAmbienceA4);
} else mus_change(musArea4A);
// Keep these destroyed blocks from regenerating during this room visit.
with (oBlockPBomb) regentime = -1;

if (global.event[200] == 0) {
    mus_change(musCaveAmbienceA4);
} else mus_change(musArea4A);

// Create the pickups selected by this game's item mapping.
instance_create(16, 3104, scr_itemsopen(oControl.mod_258));