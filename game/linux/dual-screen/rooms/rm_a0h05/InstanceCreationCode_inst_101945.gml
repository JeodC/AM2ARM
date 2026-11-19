// Keep this saved Metroid encounter only while its room progress conditions allow it.
if (global.event[0] == 0) {
    instance_destroy();
    exit;
}
init_monster_trigger(0, 1);