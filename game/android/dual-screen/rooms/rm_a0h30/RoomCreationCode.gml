// Offset this room's local map cells into the world map.
global.mapoffsetx = 40;
global.mapoffsety = 41;
// Restore the lava and remaining scenery for the saved drainage stage.
if (global.lavastate <= 6) {
    make_liquid(1, 176, 0, 0, 0, 0, 0);
} else {
    global.watertype = 0;
    global.waterlevel = 0;
    tile_layer_delete(-90);
}
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Keep these destroyed blocks from regenerating during this room visit.
with (oBlockSpeed) regentime = -1;