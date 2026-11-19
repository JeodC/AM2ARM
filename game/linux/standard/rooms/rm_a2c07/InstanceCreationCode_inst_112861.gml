// Keep this saved Metroid encounter only while its room progress conditions allow it.
init_monster_trigger(12, -1);
if (global.metdead[11] == 0 || global.event[109] == 0) instance_destroy();