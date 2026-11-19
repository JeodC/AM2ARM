if (!instance_exists(oCharacter)) {
    room_goto(rm_secretEnding);
    
    /*mus_stop_all();
    mus_play_once(musCredits);
    room_goto(rm_credits);*/
}


if (instance_exists(oCharacter) && (keyboard_check(vk_shift))) {
    //room_goto(rm_a8h01);
    msg = get_string("WARP TO", "rm_a0h01");
    var rm = asset_get_index(msg);
    if (room_exists(rm)) {
        room_goto(rm);
    } else {
        popup_text("Room index does not exist!");
    }
}

/*if (keyboard_check(vk_shift)) {
    msg = get_integer_async("WARP TO", 0);
} else {
    //global.targetx = 160;
    //global.targety = 120;
    global.targetx = 64;
    global.targety = 64;
    //targetroom = asset_get_index("rm_a7b10");
    targetroom = asset_get_index("a5b03a");
    
    if (global.ingame) room_goto(targetroom);
}

// - Code for outputting sand maps to text file.
/*
fileSand = file_text_open_write(working_directory + "\fileSand.txt");

sand_str = ds_map_write(global.sand_map);
file_text_write_string(fileSand,sand_str);
file_text_writeln(fileSand);
sandcrn0_str = ds_map_write(global.sandcrn0_map);
file_text_write_string(fileSand,sandcrn0_str);
file_text_writeln(fileSand);
sandcrn1_str = ds_map_write(global.sandcrn1_map);
file_text_write_string(fileSand,sandcrn1_str);
file_text_writeln(fileSand);
sandcrn2_str = ds_map_write(global.sandcrn2_map);
file_text_write_string(fileSand,sandcrn2_str);
file_text_writeln(fileSand);
sandcrn3_str = ds_map_write(global.sandcrn3_map);
file_text_write_string(fileSand,sandcrn3_str);
file_text_writeln(fileSand);
//string(ds_map_find_value(global.sand_map,key));
/*for(i = 0; i < ds_map_size(global.sand_map); i ++) {
    sand_str = sand_str + string(ds_map_find_value(global.sand_map,key_sand));
    key_sand = ds_map_find_next(global.sand_map,key_sand);
}

file_text_close(fileSand);
*/

/*


if (keyboard_check(vk_shift)) {
    msg = get_integer_async("WARP TO", 0);
} else {
    //global.targetx = 160;
    //global.targety = 120;
    global.targetx = 900;
    global.targety = 150;
    //targetroom = asset_get_index("rm_a7b10");
    targetroom = asset_get_index("rm_a7c01");
    
    if (global.ingame) room_goto(targetroom);
}


/* */
/*  */
