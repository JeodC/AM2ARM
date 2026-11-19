i = x + y;
image_speed = 0;
color = 0;


// Stable cosmetic density; retain all instances and their warning state.
nano_tile_slot = global.nano_tile_counter;
global.nano_tile_counter = (global.nano_tile_counter + 1) mod 4;
