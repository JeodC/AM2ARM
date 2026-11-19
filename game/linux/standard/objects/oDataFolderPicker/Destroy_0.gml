global.am2r_sync.transfer = false;
if (action == "backup") {
    var _names = ["save1", "save2", "save3", "data.sav", "extras.sav"];
    for (var _i = 0; _i < array_length(_names); ++_i) file_delete("backupstage_" + _names[_i]);
}
if (instance_exists(owner)) {
    for (var _i = 0; _i <= owner.lastitem; ++_i)
        if (instance_exists(owner.op[_i])) owner.op[_i].visible = true;
    if (active) owner.alarm[0] = 5;
    if (!owner.result_pending) global.tiptext = owner.tip[global.curropt];
}
