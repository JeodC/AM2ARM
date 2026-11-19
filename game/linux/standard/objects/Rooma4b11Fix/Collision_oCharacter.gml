// Remove these two room-placed Speed Booster blocks when the saved item flag is unset.
if (global.item[7] == 0)
{
    with (inst_130077) { instance_destroy(); }
    with (inst_130078) { instance_destroy(); }
}

instance_destroy();


