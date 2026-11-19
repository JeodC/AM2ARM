
// Keep this saved Metroid encounter only while its room progress conditions allow it.
init_monster_trigger(41, 1);
if (global.lavastate > 8) instance_destroy();
