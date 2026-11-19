/// @description Async - Social: AM2RSaveTransfer results
if (os_type != os_android) exit;
if (async_load[? "type"] == "am2r_savesync") {
    save_sync_result(async_load);
    exit;
}
if (async_load[? "type"] != "am2r_savetransfer") exit;
global.am2r_sync.transfer = false;

var _action = async_load[? "action"];
var _ok = async_load[? "success"];
var _files = async_load[? "files"];

// files == -1 means the player cancelled the picker -- no message at all.
if (_files < 0) {
    if (_action == "backup") {
        var names = ["save1", "save2", "save3", "data.sav", "extras.sav"];
        for (var n = 0; n < array_length(names); n++) file_delete("backupstage_" + names[n]);
    }
    exit;
}

var _f1 = async_load[? "found_save1"];  if (is_undefined(_f1)) _f1 = 0;
var _f2 = async_load[? "found_save2"];  if (is_undefined(_f2)) _f2 = 0;
var _f3 = async_load[? "found_save3"];  if (is_undefined(_f3)) _f3 = 0;
var _fu = async_load[? "found_unlocks"]; if (is_undefined(_fu)) _fu = 0;

// Pass the transfer result to the data menu so its next update can handle it.
with (oOptionsData) {
    result_pending = 1;
    result_action = _action;
    result_ok = _ok;
    result_files = _files;
    found1 = _f1;
    found2 = _f2;
    found3 = _f3;
    foundu = _fu;
}
