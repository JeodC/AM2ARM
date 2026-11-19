// Keep this saved Metroid encounter only while its room progress conditions allow it.
init_monster_trigger(23, -1);
if (global.event[171] == 0) instance_destroy();