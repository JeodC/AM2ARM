if (editing && global.curropt >= 0 && global.curropt <= 14 && keyboard_key != vk_nokey) {
    // Resolve duplicate bindings while keeping Start separate from the menu accept and back keys.
    if (global.curropt < 12 || global.curropt == 12 && global.opkeybtn_menu1 != keyboard_key && global.opkeybtn_menu2 != keyboard_key) {
        remap_duplicate_kbkey(keyboard_key);
        map_kbkey(global.curropt, keyboard_key);
    } else if (global.curropt > 12 && global.opkeybtn_start != keyboard_key) {
        remap_duplicate_kbkeymenu(keyboard_key);
        map_kbkey(global.curropt, keyboard_key);
    }
    // Clear the captured key and briefly suspend navigation so the new binding is not also a menu command.
    io_clear();
    event_user(2);
    alarm[2] = 1;
    active = 0;
    alarm[0] = 5;
}

