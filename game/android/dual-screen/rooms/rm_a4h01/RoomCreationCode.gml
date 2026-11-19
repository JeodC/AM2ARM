// Offset this room's local map cells into the world map.
global.mapoffsetx = 36;
global.mapoffsety = 35;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate <= 6) make_liquid(1, 1644, 0, 0, 0, 0, 1);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Set the darkness level consumed by room lighting setup.
global.darkness = 0;
// Choose the room music from the saved facility power-switch state.
if (global.event[200] == 0) {
    mus_change(musCaveAmbienceA4);
} else mus_change(musArea4A);


/*
if (oControl.mod_250 != 0 && oControl.mod_250 != 2 && oControl.mod_250 != 4 && oControl.mod_250 != 6)
{
    var t = scr_itemchange(250);
}
*/

// Create the pickups selected by this game's item mapping.
instance_create(48, 1872, scr_itemsopen(oControl.mod_250));
//instance_create(48, 1872, scr_itemchange(250));