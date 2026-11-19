// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 10;
global.mapoffsety = 23;
global.waterlevel = 0;
global.floormaterial = 3;
// Restore the lava and remaining scenery for the saved drainage stage.
if (global.lavastate <= 10) {
    make_liquid(1, 200, 0, 0, 0, 0, 0);
} else tile_layer_delete(-99);
mus_change(musItemAmb);

//if (oCharacter.x > 320) oCamera.x = 624; // whoopsies