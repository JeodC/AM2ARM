// Offset this room's local map cells into the world map.
global.mapoffsetx = 52;
global.mapoffsety = 42;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 1520, 0, 0, 0, 0, 1);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Choose the room music from the saved distribution-center power state.
if (global.event[250] > 0) {
    mus_change(musArea5B);
} else mus_change(musArea5A);
// Schedule the environment scan if its log state permits it.
scan_log(28, get_text("ScanEvents", "ScanEnvironment"), 120, 0);

// Create the pickups selected by this game's item mapping.
instance_create(528, 304, scr_itemsopen(oControl.mod_309));