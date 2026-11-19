/// Correct only the RG DS built-in controller's inactive analog trigger bindings.
function rgds_trigger_mapping(_model, _controller, _mapping) {
    var _device = string_lower(string_replace_all(string_replace_all(_model, "_", ""), " ", ""));
    if (_device != "rgds" || _controller != "retrogame_joypad") return _mapping;

    // The pinned Android runner receives BUTTON_L2/R2 at native button 17/18.
    // Keep every other binding, including existing custom trigger mappings.
    var _result = string_replace_all(_mapping, ",lefttrigger:a4,", ",lefttrigger:b17,");
    return string_replace_all(_result, ",righttrigger:a5,", ",righttrigger:b18,");
}

/// Apply on discovery/settings changes, never in the per-frame input path.
function android_gamepad_configure(_restore = false) {
    if (os_type != os_android) return;
    static _model = undefined;
    static _original = [];
    static _corrected = [];
    if (is_undefined(_model)) {
        var _info = os_get_info();
        _model = string(ds_map_find_value(_info, "MODEL"));
        ds_map_destroy(_info);
    }
    var _raw_mode = _restore || global.compatibilitymode;
    for (var _slot = 0; _slot < gamepad_get_device_count(); _slot++) {
        if (!gamepad_is_connected(_slot)) continue;
        var _current = gamepad_get_mapping(_slot);
        var _name = gamepad_get_description(_slot);
        if (_slot >= array_length(_original)) {
            _original[_slot] = "";
            _corrected[_slot] = "";
        }

        // A reconnected or replaced pad can reuse a slot. Never restore a
        // previous controller's map over a newly discovered device's map.
        if (_current != _corrected[_slot] && _current != _original[_slot]) {
            _original[_slot] = "";
            _corrected[_slot] = "";
        }
        if (_raw_mode) {
            // Raw button indices change when a button becomes mapped. Keep
            // Compatibility Mode's saved assignments exactly as they were.
            if (_current == _corrected[_slot] && _original[_slot] != "") {
                gamepad_test_mapping(_slot, _original[_slot]);
            }
            continue;
        }
        var _next = rgds_trigger_mapping(_model, _name, _current);
        if (_next == _current) continue;
        var _guid = gamepad_get_guid(_slot);
        var _comma = string_pos(",", _current);
        if (string_length(_guid) != 32 || _comma == 0) continue;
        // Generated maps can start with "none"; a submitted SDL map needs
        // the actual controller GUID. The bindings themselves stay intact.
        _original[_slot] = _guid + string_copy(_current, _comma, string_length(_current));
        _corrected[_slot] = _guid + string_copy(_next, string_pos(",", _next), string_length(_next));
        gamepad_test_mapping(_slot, _corrected[_slot]);
    }
}
