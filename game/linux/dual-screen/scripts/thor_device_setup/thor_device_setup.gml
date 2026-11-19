// Saved hardware profiles and first-run display setup.
// Runs in oControl scope. Profile numbers and persisted option values are stable interfaces.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

// Only implemented profiles appear in this dedicated dual-display build.
function thor_profile_load() {
    ini_open("config.ini");
    var _profile = ini_read_real("DualScreen", "DeviceProfile", -1);
    var _valid = ini_key_exists("DualScreen", "DeviceProfile") && _profile >= 0
        && _profile < array_length(thor_profiles) && _profile == floor(_profile);
    // Older RG DS installs had no Nano option. Apply its default once, while
    // preserving an explicit Off value from this or a previous Nano build.
    if (_valid && _profile == 1 && !ini_key_exists("Screen", "Nano")) {
        global.nano_enabled = true;
        ini_write_real("Screen", "Nano", 1);
    }
    ini_close();
    thor_setup_saved_swap = thor_swap_screens;
    // Require hardware setup when the saved profile is missing or invalid, with a default layout until selection.
    thor_setup_needed = thor_enabled && !_valid;
    thor_profile_apply(_valid ? _profile : 0);
    if (thor_aspect_locked) {
        global.widescreen_enabled = 0; widescreen = false; widescreen_space = 0;
        __view_set(e__VW.Visible, 1, false);
    }
}

function thor_setup_hit(_x, _y) {
    if (_x < 36 || _x > 284) return -1;
    var _top = thor_setup_stage == 1 ? 128 : 64;
    var _count = thor_setup_stage == 1 ? 2 : 4;
    for (var _i = 0; _i < _count; ++_i) {
        if (_y >= _top + 32 * _i && _y <= _top + 24 + 32 * _i) return _i;
    }
    return -1;
}

function thor_setup_step() {
    // Require the opening confirm or direction buttons to be released before setup can accept a choice.
    if (!thor_setup_ready) {
        thor_setup_ready = !(kMenu1 || kMenu2 || kStart || kUp || kDown);
        thor_setup_tap = -1;
        return;
    }
    if (thor_setup_stage == 1 && kMenu2 && kMenu2PushedSteps == 0) {
        thor_setup_stage = 0;
        thor_setup_choice = 1;
        thor_setup_ready = false;
        thor_swap_screens = thor_setup_saved_swap;
        thor_profile_apply(0);
        return;
    }
    var _previous_choice = thor_setup_choice;
    var _last = thor_setup_stage == 1 ? 1 : 3;
    if (kUp && kUpPushedSteps == 0) thor_setup_choice = wrap(thor_setup_choice - 1, 0, _last);
    if (kDown && kDownPushedSteps == 0) thor_setup_choice = wrap(thor_setup_choice + 1, 0, _last);
    if (thor_setup_choice != _previous_choice) sfx_play(sndMenuMove);
    if (device_mouse_check_button_pressed(0, mb_left)) {
        var _scale = max(1, floor(min(window_get_width() / 320, window_get_height() / 240)));
        var _x = (device_mouse_x_to_gui(0) - round((window_get_width() - 320 * _scale) / 2)) / _scale;
        var _y = (device_mouse_y_to_gui(0) - round((window_get_height() - 240 * _scale) / 2)) / _scale;
        thor_setup_tap = thor_setup_hit(_x, _y);
    }
    var _confirm = (kMenu1 && kMenu1PushedSteps == 0) || (kStart && kStartPushedSteps == 0);
    if (thor_setup_tap >= 0) {
        thor_setup_choice = thor_setup_tap;
        _confirm = true;
    }
    thor_setup_tap = -1;
    if (!_confirm) return;
    sfx_play(sndMenuSel);
    if (thor_setup_stage == 1) {
        if (thor_setup_choice == 1) {
            // Preview the output route without saving an unfinished setup.
            thor_swap_screens = !thor_swap_screens;
            thor_lower_step = -1;
            Thor_Swap(thor_profile, thor_swap_screens);
            thor_setup_choice = 0;
            thor_setup_ready = false;
            return;
        }
        thor_setup_finish();
        return;
    }
    thor_profile_apply(thor_setup_order[thor_setup_choice]);
    if (thor_profile == 1) {
        thor_setup_stage = 1;
        thor_setup_choice = 0;
        thor_setup_ready = false;
        return;
    }
    thor_setup_finish();
}

function thor_setup_finish() {
    // A valid saved profile skips setup; later user choices are never overridden.
    if (thor_profile == 1) global.nano_enabled = true;
    global.widescreen_enabled = !thor_aspect_locked;
    widescreen = global.widescreen_enabled;
    widescreen_space = widescreen ? 106 : 0;
    if (!widescreen) __view_set(e__VW.Visible, 1, false);
    ini_open("config.ini");
    ini_write_real("DualScreen", "DeviceProfile", thor_profile);
    if (thor_swap_supported(thor_profile)) {
        ini_write_real("DualScreen", thor_swap_key(thor_profile), thor_swap_screens ? 1 : 0);
    }
    ini_close();
    save_gameoptions();
    thor_setup_needed = false;
    if (surface_exists(thor_setup_surface)) surface_free(thor_setup_surface);
    thor_setup_surface = -1;
    // Resume the original startup event only after a hardware choice is saved.
    alarm[0] = 1;
}

function thor_draw_setup_upper() {
    if (!thor_setup_needed) return false;
    if (!surface_exists(thor_setup_surface)) thor_setup_surface = surface_create(320, 240);
    // Draw hardware setup into a native-size surface that both panels can display.
    var _matrix = matrix_get(matrix_world);
    var _font = draw_get_font(), _color = draw_get_color(), _alpha = draw_get_alpha();
    var _ha = draw_get_halign(), _va = draw_get_valign();
    matrix_set(matrix_world, matrix_build_identity());
    surface_set_target(thor_setup_surface);
    draw_clear(c_black);
    thor_setup_draw_page(true);
    surface_reset_target();
    var _scale = max(1, floor(min(window_get_width() / 320, window_get_height() / 240)));
    draw_surface_ext(thor_setup_surface, round((window_get_width() - 320 * _scale) / 2),
        round((window_get_height() - 240 * _scale) / 2), _scale, _scale, 0, c_white, 1);
    matrix_set(matrix_world, _matrix);
    draw_set_font(_font); draw_set_color(_color); draw_set_alpha(_alpha);
    draw_set_halign(_ha); draw_set_valign(_va);
    return true;
}

function thor_setup_draw_page(_gameplay) {
    draw_set_alpha(1);
    draw_set_font(fontGUI2);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(12, 52, 4));
    draw_rectangle(0, 22, 320, 44, false);
    draw_set_color(c_white);
    var _order = thor_setup_stage == 1;
    draw_text(160, 33, _order ? port_caption("CHECK SCREEN ORDER") : port_caption("CHOOSE YOUR HARDWARE"));
    if (_order) {
        draw_text(160, 72, _gameplay ? port_caption("GAMEPLAY") : port_caption("MAP AND MENUS"));
        draw_set_font(fontMenuSmall);
        draw_text(160, 94, port_caption("Gameplay above, map below."));
        draw_set_font(fontGUI2);
    }
    var _count = _order ? 2 : 4;
    for (var _i = 0; _i < _count; ++_i) {
        var _top = (_order ? 128 : 64) + _i * 32;
        draw_set_color(_i == thor_setup_choice ? make_color_rgb(16, 72, 4) : make_color_rgb(3, 16, 2));
        draw_rectangle(36, _top, 284, _top + 24, false);
        draw_set_color(_i == thor_setup_choice ? make_color_rgb(100, 240, 80) : make_color_rgb(24, 72, 12));
        draw_rectangle(36, _top, 284, _top + 24, true);
        draw_set_color(c_white);
        draw_text(160, _top + 12, _order ? (_i == 0 ? port_caption("KEEP THIS ORDER") : port_caption("SWAP DISPLAYS")) : thor_setup_labels[_i]);
    }
    draw_set_font(fontMenuSmall);
    if (_order) draw_text(160, 205, port_caption("Nano starts enabled on RG DS."));
    draw_text(160, _order ? 220 : 212, port_caption("Change this later in Display settings."));
}

function thor_apply_hud_layout() {
    // Top placement leaves only the title/counter row above the map.
    thor_map_top = ceil(thor_art_header_rows() * thor_art_scale);
    thor_map_bottom = thor_height - ceil(31 * thor_art_scale);
    thor_layout_controls();
    thor_next_map = 0;
}

function thor_profile_apply(_profile) {
    // Apply the selected hardware dimensions to the lower canvas, toolbar, pause-page origin, and shared scene.
    thor_profile = clamp(round(_profile), 0, array_length(thor_profiles) - 1);
    // The USB add-on is opt-in. Preserve the existing RG DS screen-order key
    // independently, including when the player changes profiles in Display.
    thor_swap_screens = false;
    if (thor_swap_supported(thor_profile)) {
        ini_open("config.ini");
        thor_swap_screens = ini_read_real("DualScreen", thor_swap_key(thor_profile), 0) == 1;
        ini_close();
    }
    var _layout = thor_profiles[thor_profile];
    thor_width = _layout.width;
    thor_height = _layout.height;
    thor_scene_width = _layout.scene_width;
    thor_page_y = _layout.page_y;
    thor_aspect_locked = _layout.aspect_locked;
    thor_pad = (thor_width - 310) / 2;
    thor_layout_controls();
    thor_map_bottom = thor_height - 38;
    thor_apply_hud_layout();
    thor_page_buttons_top = _layout.page_buttons;
    // The native menu and its touch sectors share the fixed page frame.
    thor_menu_center_y = 121;
    thor_art_reset_images();
    // Discard images and transfer storage whose dimensions belong to the previous profile.
    if (surface_exists(thor_surface)) surface_free(thor_surface);
    if (surface_exists(thor_transition_surface)) surface_free(thor_transition_surface);
    if (surface_exists(thor_death_surface)) surface_free(thor_death_surface);
    if (surface_exists(thor_scene)) surface_free(thor_scene);
    if (surface_exists(thor_room_surface)) surface_free(thor_room_surface);
    if (buffer_exists(thor_buffer)) buffer_delete(thor_buffer);
    thor_surface = thor_transition_surface = thor_death_surface = thor_scene = thor_buffer = -1;
    thor_room_surface = -1;
    thor_output_room = -1;
    thor_transition_until = 0;
    // Request the matching Android canvas size; its UI-thread resize completes separately.
    if (thor_enabled) {
        Thor_SetSize(thor_width, thor_height);
        Thor_Swap(thor_profile, thor_swap_screens);
    }
}

function thor_swap_supported(_profile) {
    return _profile == 1 || _profile == 2;
}

function thor_swap_key(_profile) {
    return _profile == 1 ? "RGDSSwapScreens" : "RetroidAddon";
}

function thor_swap_active() {
    if (os_type == os_linux) return false; // Linux routes the two native windows directly.
    return thor_enabled && thor_swap_supported(thor_profile) && thor_swap_screens && Thor_Ready() > 0;
}

function thor_swap_set(_enabled) {
    if (!thor_enabled || !thor_swap_supported(thor_profile)) return;
    thor_swap_screens = _enabled;
    thor_lower_step = -1;
    ini_open("config.ini");
    ini_write_real("DualScreen", thor_swap_key(thor_profile), thor_swap_screens ? 1 : 0);
    ini_close();
    Thor_Swap(thor_profile, thor_swap_screens);
}
