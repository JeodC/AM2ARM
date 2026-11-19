// Linux supplies folder access; the shared save converters validate game data.
function linux_save_init() {
    var _root = environment_get_variable("AM2ARM_SAVE_DIR");
    if (_root == "") _root = environment_get_variable("HOME") + "/.config/AM2RStandardLinux";
    global.linux_save_ready = AM2ARM_SaveInit(_root) == 1;
    global.linux_save_folder = environment_get_variable("AM2ARM_BROWSE_DIR");
    return global.linux_save_ready;
}

function linux_save_picker(_owner, _action) {
    if (!global.linux_save_ready || instance_exists(oDataFolderPicker)) return false;
    var _picker = instance_create(0, 0, oDataFolderPicker);
    _picker.owner = _owner;
    _picker.action = _action;
    _owner.active = 0;
    _owner.alarm[0] = -1;
    for (var _i = 0; _i <= _owner.lastitem; ++_i) _owner.op[_i].visible = false;
    _picker.folder_load(global.linux_save_folder);
    return true;
}

function save_transfer_apply(_source, _target) {
    if (os_type == os_linux) return AM2ARM_SaveApply(_source, _target);
    return SaveTransfer_Apply(_source, _target);
}

function linux_folder_label(_text, _width) {
    var _label = string_replace_all(string_replace_all(_text, "\n", " "), "\r", " ");
    if (string_width(_label) <= _width) return _label;
    while (string_length(_label) > 1 && string_width(_label + "...") > _width)
        _label = string_delete(_label, string_length(_label), 1);
    return _label + "...";
}
