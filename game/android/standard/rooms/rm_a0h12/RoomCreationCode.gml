// Offset this room's local map cells into the world map.
global.mapoffsetx = 42;
global.mapoffsety = 26;
// Create the lava surface and its background and immersion effects.
make_liquid(1, 192, 0, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
mus_change(musCaveAmbience);