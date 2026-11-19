// Offset this room's local map cells into the world map.
global.mapoffsetx = 69;
global.mapoffsety = 50;
// Treat the whole room as underwater, with the water surface above the room.
make_deep_water();
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 4;
// Choose the room music from the saved distribution-center power state.
if (global.event[250] > 0) {
    mus_change(musArea5B);
} else mus_change(musArea5A);