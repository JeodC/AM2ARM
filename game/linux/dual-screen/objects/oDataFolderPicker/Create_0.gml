depth = -100;
owner = noone;
action = "backup";
active = true;
wait_frames = 5;
folder = "";
entries = [];
selected = 0;
scroll = 0;
page_rows = 8;
path_label = "";

function folder_load(_path) {
    var _result = json_parse(AM2ARM_SaveList(_path));
    if (!_result.ok) {
        global.tiptext = port_caption("Could not keep access to that folder.");
        if (array_length(entries) == 0) {
            entries = [{label:port_caption("Cancel"), path:"", kind:"cancel"}];
        }
        return;
    }
    folder = _result.path;
    global.linux_save_folder = folder;
    entries = [{label:get_text("Misc", "PickerUseFolder"), path:folder, kind:"use"}];
    if (_result.parent != folder && _result.parent != "")
        array_push(entries, {label:"[..] " + get_text("Misc", "PickerParent"), path:_result.parent, kind:"folder"});
    for (var _i = 0; _i < array_length(_result.dirs); ++_i)
        array_push(entries, {label:"[+] " + _result.dirs[_i].name, path:_result.dirs[_i].path, kind:"folder"});
    array_push(entries, {label:port_caption("Cancel"), path:"", kind:"cancel"});
    selected = 0;
    scroll = 0;
    draw_set_font(fontGUI2);
    path_label = folder;
    while (string_length(path_label) > 1 && string_width("..." + path_label) > 272)
        path_label = string_delete(path_label, 1, 1);
    if (path_label != folder) path_label = "..." + path_label;
    global.tiptext = get_text("Misc", action == "backup" ? "BackupSaves_Tip" : "RestoreSaves_Tip");
}

function folder_accept() {
    var _entry = entries[selected];
    if (_entry.kind == "cancel") { instance_destroy(); return; }
    if (_entry.kind == "folder") { folder_load(_entry.path); return; }
    if (!instance_exists(owner)) { instance_destroy(); return; }
    var _result = json_parse(action == "backup" ? AM2ARM_SaveExport(folder) : AM2ARM_SaveImport(folder));
    owner.result_action = action;
    owner.result_ok = _result.ok;
    owner.result_files = _result.files;
    owner.result_pending = true;
    instance_destroy();
}
