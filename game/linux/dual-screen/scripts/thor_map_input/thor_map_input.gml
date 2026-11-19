// Lower-map control bounds, controller input and gestures.
// Runs in oControl scope. Drawing and hit testing share the same layout coordinates.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

function thor_layout_controls() {
    // The same native artwork and touch bounds serve both HUD positions.
    var _r = thor_art_scale, _w = thor_art_width;
    var _left = -thor_pad + (thor_width - _w * _r) / 2;
    var _starts = [0, 18, 36, 69, 127 + floor((_w - 177) / 2)];
    var _ends = [17, 35, 68, _starts[4] - 1, _w];
    thor_map_buttons = array_create(5);
    thor_action_buttons = array_create(3);
    for (var _i = 0; _i < 5; ++_i)
        thor_map_buttons[_i] = [_left + _starts[_i] * _r, _left + _ends[_i] * _r];
    for (var _i = 0; _i < 3; ++_i)
        thor_action_buttons[_i] = [_left + floor(_w * _i / 3) * _r,
            _left + (floor(_w * (_i + 1) / 3) - (_i < 2 ? 1 : 0)) * _r];
}

// Return the toolbar slot containing this horizontal position, or no slot when the tap falls in a gap.
function thor_toolbar_hit(_buttons, _x) {
    for (var _i = 0; _i < array_length(_buttons); ++_i) {
        if (_x >= _buttons[_i][0] && _x <= _buttons[_i][1]) return _i;
    }
    return -1;
}

function thor_map_action(_action) {
    // A toolbar action replaces the current pinch adjustment with a zoom, overview, or follow choice.
    thor_gesture_until = 0;
    sfx_play(sndMenuMove);
    switch (_action) {
        case 1:
            var _next = thor_zoom > 2 ? 2 : (thor_zoom > 1 ? 1 : (thor_zoom > 0.5 ? 0.5 : 0.25));
            thor_zoom = min(thor_zoom, max(min(1, thor_map_fit_zoom()), _next));
            thor_overview = false;
            break;
        case 2: thor_zoom = thor_zoom < 0.5 ? 0.5 : (thor_zoom < 1 ? 1 : (thor_zoom < 2 ? 2 : 4)); thor_overview = false; break;
        case 3: thor_follow = false; thor_overview = true; break;
        case 4: thor_zoom = thor_manual_zoom; thor_follow = true; thor_overview = false; break;
        case 5: thor_zoom = 1; thor_overview = false; break;
    }
    // Remember deliberate zoom changes so Follow can return from the temporary Fit Map view.
    if (_action == 1 || _action == 2 || _action == 5) thor_manual_zoom = thor_zoom;
}

function thor_map_fit_zoom() {
    // Quarter-pixel cell steps use the available height on shorter panels.
    // Tile boundaries are snapped individually; the finished map is never resized.
    var _cell = max(2, floor(4 * min(16, (thor_width - 16) / max(1, thor_map_max_x - thor_map_min_x),
        (thor_map_bottom - thor_map_top - 4) / max(1, thor_map_max_y - thor_map_min_y))) / 4);
    if (_cell >= 8) _cell = 8 * floor(_cell / 8);
    return _cell / 8;
}

function thor_map_pick_cell(_pixel, _origin) {
    // Invert the same rounded tile boundaries used by the compact map.
    return ceil((floor(_pixel - _origin) + 0.5) / (8 * thor_zoom)) - 1;
}

function thor_map_pad_available(_button) {
    // Preserve confirm/menu/pause and the original collected-item toggle before shortcuts.
    return global.joydetected && !global.compatibilitymode && gamepad_is_connected(global.opjoyid)
        && _button != global.opxjoybtn_menu1 && _button != global.opxjoybtn_menu2
        && _button != global.opxjoybtn_str && _button != global.opxjoybtn_r;
}

function thor_map_toolbar_input(_input, _paused) {
    if (!_paused && _input.tap && _input.y >= thor_art_map_controls_top() && _input.y < thor_height) {
        var _button = thor_toolbar_hit(thor_map_buttons, _input.x);
        if (_button >= 0) thor_map_action([2, 1, 5, 3, 4][_button]);
    }
    if (_paused && instance_exists(oMapCursor) && oMapCursor.active) {
        var _buttons = [gp_shoulderl, gp_shoulderr, gp_face4, gp_face3];
        for (var _b = 0; _b < 4; ++_b) {
            if (thor_map_pad_available(_buttons[_b]) && gamepad_button_check_pressed(global.opjoyid, _buttons[_b])) {
                thor_map_action(_b + 1);
            }
        }
    }
}

// Merge touch actions before global_control() derives pressed/held states.
// The same existing menu events handle controller buttons and lower-screen taps.
function thor_input() {
    if (!thor_enabled) exit;
    // Consume one batch of lower-screen gestures before oControl converts raw controls into pressed and held states.
    var _payload = Thor_Input();
    var _input = _payload == "" ? thor_idle_input : json_parse(_payload);
    if (_payload != "") thor_nano_dirty = true;
    if (_payload != "") _input.x -= thor_pad;
    if (thor_setup_needed) {
        if (_input.tap) thor_setup_tap = thor_setup_hit(_input.x + 5, _input.y - floor((thor_height - 240) / 2));
        return;
    }
    thor_marker_pan = false;
    if (thor_frontend_input(_input)) return;

    if (room == rm_subscreen) {
        if (instance_exists(oSS_Fg) && oSS_Fg.fadeout) {
            ctrl_Menu1 = ctrl_Menu2 = ctrl_Start = 0;
            thor_pending_action = 0;
            exit;
        }
        var _map_page = global.ssmode == 0 && !instance_exists(oSubScrChange);
        // A direction held in gameplay must be released before it can browse the paused map.
        if (!(ctrl_Left || ctrl_Right || ctrl_Up || ctrl_Down)) thor_pause_direction_ready = true;
        if (!thor_pause_direction_ready) ctrl_Left = ctrl_Right = ctrl_Up = ctrl_Down = 0;
        // Replay a gameplay toolbar request only after the pause page has finished opening.
        if (thor_pending_action != 0 && instance_exists(oSS_Fg) && oSS_Fg.active && !oSS_Fg.fadein) {
            if (thor_pending_action == 1 && _map_page && instance_exists(oMapCursor) && oMapCursor.active) {
                ctrl_Menu1 = 1;
                thor_pending_action = 0;
            } else if (thor_pending_action == 2 && oSS_Control.canchange && !instance_exists(oSubScrChange)) {
                ctrl_Menu2 = 1;
                thor_pending_action = 0;
            }
        }
        if (_input.tap && _input.y >= ( _map_page ? thor_art_map_controls_top() : thor_art_page_controls_top())) {
            var _button = thor_toolbar_hit(thor_action_buttons, _input.x);
            if (_button == 0) ctrl_Menu1 = 1;
            if (_button == 1) ctrl_Menu2 = 1;
            if (_button == 2) ctrl_Start = 1;
        }
        // Pause pages retain their native pixels, centered inside the 310-pixel panel.
        var _px = _input.x + 5, _py = _input.y - thor_page_y;
        if (instance_exists(oSubScrChange)) {
            if (_input.tap && _input.y < thor_art_page_controls_top() && oSubScrChange.state == 1) {
                // The original four-way menu also accepts a tap on each sector.
                var _menu_y = thor_menu_center_y;
                if (abs(_px - 160) > abs(_py - _menu_y)) {
                    if (_px < 160) ctrl_Left = 1; else ctrl_Right = 1;
                } else {
                    if (_py < _menu_y) ctrl_Up = 1; else ctrl_Down = 1;
                }
            }
        } else if (_map_page && instance_exists(oMapCursor)) {
            // Pause activates controls on the permanent map; no second map viewport.
            thor_map_gesture(_input);
            thor_map_toolbar_input(_input, true);
            var _moving = ctrl_Left || ctrl_Right || ctrl_Up || ctrl_Down;
            if (_moving && oMapCursor.active) {
                thor_follow = false;
                thor_overview = false;
                if (oMapCursor.state == 1) thor_marker_pan = true;
                else {
                    thor_center_x += (ctrl_Right - ctrl_Left) / (4 * thor_zoom);
                    thor_center_y += (ctrl_Down - ctrl_Up) / (4 * thor_zoom);
                }
            }
            if (_input.tap && _input.y >= thor_map_top && _input.y < thor_map_bottom && oMapCursor.state == 1) {
                var _ox = round(155 - thor_center_x * 8 * thor_zoom);
                var _oy = round((thor_map_top + thor_map_bottom) / 2 - thor_center_y * 8 * thor_zoom);
                global.mapmarkerx = clamp(thor_map_pick_cell(_input.x, _ox), 3, 76);
                global.mapmarkery = clamp(thor_map_pick_cell(_input.y, _oy), 3, 59);
                with (oMapMarker) event_user(0);
            }
        // Resolve a settings-page tap against editable row instances in their scrolled world coordinates.
        } else if (global.ssmode == 3 && _input.tap && _py >= 42 && _py < 198) {
            // Wrapped translated help can cover the lowest menu rows. Match
            // the visible panel so a tap on its text cannot change a setting.
            if (instance_exists(oSS_Fg)
                && _py >= oSS_Fg.port_help_top) exit;
            var _world_x = __view_get(e__VW.XView, 0) + _px;
            var _world_y = __view_get(e__VW.YView, 0) + _py;
            var _chosen = noone;
            var _rows = [oPauseOption, oOptionLR, oOptionSlider];
            for (var _r = 0; _r < array_length(_rows); ++_r) {
                for (var _i = 0; _i < instance_number(_rows[_r]); ++_i) {
                    var _row = instance_find(_rows[_r], _i);
                    if (variable_instance_exists(_row, "enabled") && !_row.enabled) continue;
                    if (variable_instance_exists(_row, "canEdit") && !_row.canEdit) continue;
                    if (instance_exists(oOptionsDisplay) && oOptionsDisplay.active) {
                        if (_row.optionid < 0 || _row.optionid > oOptionsDisplay.menuSize) continue;
                        if (!oOptionsDisplay.canEdit[_row.optionid]) continue;
                    }
                    if (_world_x >= _row.x - 4 && abs(_world_y - _row.y - 2) <= 8) _chosen = _row;
                }
            }
            // Select the tapped row, then feed its confirm or left/right action into the existing menu controls.
            if (_chosen != noone) {
                global.curropt = _chosen.optionid;
                if (_chosen.object_index == oPauseOption) ctrl_Menu1 = 1;
                else if (_world_x < _chosen.x + _chosen.textoffset) ctrl_Left = 1;
                else ctrl_Right = 1;
            }
        }
        exit;
    }
    if (!global.ingame) {
        if (room != rm_transition) thor_pending_action = 0;
        exit;
    }
    thor_map_gesture(_input);
    thor_map_toolbar_input(_input, false);
    // Match the original pause gate: a cutscene tap must not queue a later menu action.
    if (!global.enablecontrol || room == rm_transition) {
        thor_pending_action = 0;
        exit;
    }
}

function thor_map_gesture(_input) {
    // Dragging from inside the map turns off following and moves its center in map-cell units.
    if (_input.originY >= thor_map_top && _input.originY < thor_map_bottom && (_input.dx != 0 || _input.dy != 0)) {
        thor_follow = false;
        thor_overview = false;
        thor_center_x -= _input.dx / (8 * thor_zoom);
        thor_center_y -= _input.dy / (8 * thor_zoom);
    }
    if (_input.zoom != 0) {
        thor_overview = false;
        if (current_time >= thor_gesture_until) thor_gesture_zoom = thor_zoom;
        thor_gesture_zoom = clamp(thor_gesture_zoom * power(2, _input.zoom), min(1, thor_map_fit_zoom()), 4);
        thor_gesture_until = current_time + 200;
        // Accumulate small pinch movements before rounding, so they never get lost.
        thor_zoom = thor_gesture_zoom < 1
            ? max(min(1, thor_map_fit_zoom()), round(thor_gesture_zoom * 32) / 32) : thor_gesture_zoom;
        thor_manual_zoom = thor_zoom;
    }
}
