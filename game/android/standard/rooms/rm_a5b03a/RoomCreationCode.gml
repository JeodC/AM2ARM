// Offset this room's local map cells into the world map.
global.mapoffsetx = 64;
global.mapoffsety = 49;
// Treat the whole room as underwater, with the water surface above the room.
make_deep_water();
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 4;
// Give step blocks a 60-step collapse delay and a 60-step regeneration delay.
with (oBlockStep) {
    delay = 60;
    regentime = 60;
}