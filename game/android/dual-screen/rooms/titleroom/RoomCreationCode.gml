// Start the title loop and clear the rumble strengths carried from gameplay.
mus_loop(musTitle);
global.vibL = 0;
global.vibR = 0;

/*
if (ds_map_exists(global.maprandom, "PureRandom")) {
    ds_map_destroy(global.maprandom);
    global.maprandom = ds_map_create();
}
*/

// Reset item mappings and game modifiers before choosing or loading another game.
scr_default_global_items();
//scr_default_maprandom();

// Remove any temporary item-swap file before starting another game.
if (file_exists(working_directory + "\\swap.ini")) file_delete(working_directory + "\\swap.ini");