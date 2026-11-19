// Offset this room's local map cells into the world map.
global.mapoffsetx = 50;
global.mapoffsety = 45;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 800, 0, 0, 0, 0, 1);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
mus_change(musCaveAmbience);
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;