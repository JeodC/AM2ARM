// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 34;
global.mapoffsety = 20;
global.waterlevel = 0;
global.watertype = 0;
// Enable the player's contact checks against upward and downward mover objects.
global.moverobj = 1;
global.floormaterial = 4;
mus_change(musArea2A);

// Create the pickups selected by this game's item mapping.
instance_create(896, 160, scr_itemsopen(oControl.mod_159));