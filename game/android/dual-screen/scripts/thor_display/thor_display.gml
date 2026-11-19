// Display state lifecycle and per-frame composition.
// Runs in oControl scope. Keep initialization, polling cadence and draw routing here.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

/// Dedicated Thor lower display. All coordinates are independent of the upper viewport.
/// @description Initialize the controller-owned display state once.
/// @context oControl
function thor_init() {
    // Use the validated pacing on every launch, independently of observation.
    display_set_timing_method(tm_sleep);
    thor_lower_step = -1;
    thor_nano_last_step = -60;
    thor_nano_last_call = current_time;
    thor_nano_previous = false;
    thor_nano_dirty = true;
    thor_nano_clock_only = false;
    thor_nano_poll_column = 0;
    thor_nano_last_health = -1;
    thor_nano_last_ammo = -1;
    thor_nano_last_super = -1;
    thor_nano_last_bombs = -1;
    thor_nano_last_weapon = -1;
    thor_nano_last_time = -1;
    thor_nano_last_items = -1;
    thor_nano_last_monsters = -1;
    thor_nano_last_area = -1;
    thor_nano_last_cell_x = -1;
    thor_nano_last_cell_y = -1;
    thor_map_columns_cache = thor_map_column_cache_new();
    thor_map_base = -1;
    thor_map_base_key = [];
    thor_map_base_revision = 0;
    thor_art_generation = 0;
    thor_art_output_key = [];
    thor_art_cache_state = [];
    thor_art_key_scratch = array_create(42, 0);
    thor_art_title_inputs = [];
    thor_art_title_state_cache = {text:"", alpha:1};
    thor_art_title_current = "";
    thor_art_title_previous = "";
    thor_art_empty_title = [0, 0, 0];
    thor_art_no_hints = [-1, -1, -1];
    thor_art_pixels = 1;
    thor_art_cache_title = [0, 0, 0];
    // oControl owns the display state initialized here and uses it from its input, draw, and cleanup events.
    thor_enabled = os_type == os_android;
    thor_controller_splash = false;
    thor_hud_top = false;
    thor_upper_hud_surface = -1;
    thor_upper_hud_buffer = -1;
    thor_upper_hud_width = 320;
    thor_idle_input = {dx:0, dy:0, zoom:0, tap:false, x:0, y:0, originX:0, originY:0};
    // Stable saved IDs. Retroid Duo and Duo Lite share one display layout.
    thor_profiles = [
        {name:"AYN Thor", width:310, height:270, scene_width:426, page_y:0, page_buttons:237, aspect_locked:false},
        {name:"RG DS", width:320, height:240, scene_width:320, page_y:0, page_buttons:226, aspect_locked:true},
        {name:"Retroid Duo", width:320, height:240, scene_width:426, page_y:0, page_buttons:226, aspect_locked:false},
        // 342x256 at 3x covers 1024x768, trimming only one empty edge pixel per side.
        {name:"AYANEO DS", width:342, height:256, scene_width:456, page_y:8, page_buttons:242, aspect_locked:false}
    ];
    thor_profile = 0;
    // RG DS exposes its lower panel as the default display on stock Android too.
    // Keep the preference separate from the profile so other handhelds are unchanged.
    thor_swap_screens = false;
    thor_setup_needed = false;
    thor_setup_stage = 0;
    thor_setup_saved_swap = false;
    thor_setup_order = [0, 1, 3, 2];
    thor_setup_labels = ["AYN THOR", "RG DS", "AYANEO DS", "RETROID POCKET DUO"];
    thor_setup_choice = 0;
    thor_setup_tap = -1;
    thor_setup_ready = false;
    thor_setup_surface = -1;
    thor_width = 310; thor_height = 270; thor_pad = 0;
    thor_scene_width = 426; thor_page_y = 0; thor_aspect_locked = false;
    thor_page_buttons_top = 237;
    // Mark render surfaces as absent; draw paths create them when their image is first needed.
    thor_surface = -1;
    thor_scene = -1;
    thor_room_surface = -1;
    thor_output_room = -1;
    thor_room_alpha = 1;
    thor_fade_step = -1;
    thor_loading_transition = false;
    thor_keep_room_map = false;
    thor_frontend_previous_mode = THOR_FRONTEND_GAMEPLAY;
    thor_death_surface = -1;
    thor_death_active = false;
    thor_title_offset = 0;
    thor_title_frame = 0;
    thor_title_press_frames = 0;
    thor_credits_voice = -1;
    thor_map = -1;
    thor_map_column = -1;
    thor_compact_map = -1;
    thor_compact_cell = 0;
    thor_compact_strip = -1;
    thor_compact_full_redraw();
    thor_corner_pixels = [];
    thor_corner_table = array_create(81, 0);
    thor_grid = -1;
    thor_hud_sheet = -1;
    thor_art_hold = -1;
    thor_art_surface = -1;
    thor_art_help_font = -1;
    thor_art_width = 177;
    thor_art_scale = 310 / 177;
    thor_art_header_height = 34;
    thor_art_health_height = 16;
    thor_art_geometry_width = -1;
    thor_art_geometry_height = -1;
    thor_art_geometry_tanks = -1;
    thor_art_geometry_hud_top = false;
    thor_art_title_full = false;
    thor_art_title_rows = 0;
    thor_art_output = -1;
    thor_art_previous = -1;
    thor_art_flash_top = -1;
    thor_art_flash_bottom = -1;
    thor_art_flash_title = -1;
    thor_art_flash_light = -1;
    thor_art_title_layout = [0, 0, 0];
    thor_art_hint_mask = 0;
    thor_art_output_hints = 0;
    thor_art_previous_hints = 0;
    thor_art_cache_hints = 0;
    thor_art_output_title = [0, 0, 0];
    thor_art_previous_title = [0, 0, 0];
    thor_art_output_top = 0;
    thor_art_output_bottom = 0;
    thor_art_previous_top = 0;
    thor_art_previous_bottom = 0;
    thor_art_output_fade = 1;
    thor_art_top_rows = 0;
    thor_art_footer_rows = 0;
    thor_buffer = -1;
    // Start the map centered on its default grid position, with player following and normal zoom enabled.
    thor_follow = true;
    thor_center_x = 40;
    thor_center_y = 40;
    thor_map_top = 54;
    thor_map_bottom = 232;
    thor_zoom = 1;
    thor_manual_zoom = 1;
    thor_gesture_zoom = 1;
    thor_gesture_until = 0;
    thor_next_map = 0;
    thor_map_valid = false;
    // Cache discovery and tile content separately so a changed map cell can trigger repainting.
    thor_map_seen = array_create(6400, -1);
    thor_map_tiles = array_create(6400, "");
    thor_last_cell_x = -1;
    thor_last_cell_y = -1;
    thor_had_game = false;
    thor_map_min_x = 0;
    thor_map_min_y = 0;
    thor_map_max_x = 80;
    thor_map_max_y = 80;
    thor_frames = 0;
    thor_steps = 0;
    thor_pause_width = 320;
    thor_pause_surface = -1;
    thor_pause_valid = false;
    thor_pause_palette = -1;
    thor_backdrop = -1;
    thor_backdrop_previous = -1;
    thor_lab_entrance = false;
    thor_previous_lab_entrance = false;
    thor_research_site = false;
    thor_previous_research_site = false;
    thor_waterfalls = false;
    thor_previous_waterfalls = false;
    thor_backdrop_since = 0;
    thor_backdrop_room = -1;
    thor_backdrop_variant = -1;
    thor_reset_area_titles();
    thor_overview = false;
    thor_marker_pan = false;
    thor_missile_frame = 0;
    thor_super_frame = 0;
    thor_bomb_frame = 0;
    // Track pause actions requested from gameplay until the destination page is ready to accept them.
    thor_pending_action = 0;
    thor_pause_direction_ready = false;
    thor_transition_surface = -1;
    thor_menu_key = -1;
    thor_ui_paused = false;
    thor_menu_center_y = 121;
    thor_transition_kind = 0;
    thor_transition_until = 0;
    // Lay out the lower controls, then request Android display discovery without waiting for a presentation.
    thor_layout_controls();
    if (thor_enabled) {
        // The lower status bar always shows the in-game timer.
        mod_IGT = 1;
        Thor_Start();
    }
}

// Nano holds idle map artwork between status changes and clock ticks. Touch gestures,
// movement between map cells and HUD changes redraw immediately. Input runs every
// step; health/ammo/cell changes, menus, transitions and missing surfaces redraw
// immediately. The gameplay output and its simulation are never gated here.
function thor_nano_reuse(_eligible, _cell_x, _cell_y) {
    thor_nano_clock_only = false;
    // The Android presentation can be replaced while the GML surface survives.
    // Resume with a fresh submission instead of waiting for the next idle tick.
    if (current_time - thor_nano_last_call > 250 || current_time < thor_nano_last_call)
        thor_nano_dirty = true;
    thor_nano_last_call = current_time;
    if (!global.nano_enabled || !_eligible) {
        thor_nano_last_step = thor_steps;
        // This frame may contain a menu or transition instead of the idle map.
        thor_nano_previous = false;
        thor_nano_dirty = false;
        return false;
    }
    // gui_health also performs this clamp on an ordinary HUD cache hit.
    if (global.playerhealth < 0) gui_health();
    var _clock_second = floor(global.gametime / 60);
    var _same = thor_nano_last_health == global.playerhealth
        && thor_nano_last_ammo == global.missiles && thor_nano_last_super == global.smissiles
        && thor_nano_last_bombs == global.pbombs && thor_nano_last_weapon == global.currentweapon
        && thor_nano_last_items == global.itemstaken
        && thor_nano_last_monsters == global.monstersleft && thor_nano_last_area == global.monstersarea
        && thor_nano_last_cell_x == _cell_x && thor_nano_last_cell_y == _cell_y;
    if (thor_nano_previous && !thor_nano_dirty && _same && surface_exists(thor_surface)
        && surface_exists(thor_map) && surface_exists(thor_grid)
        && surface_exists(thor_art_surface) && surface_exists(thor_art_output)) {
        if (thor_nano_map_changed()) thor_next_map = 0;
        else {
            if (thor_nano_last_time == _clock_second && thor_steps - thor_nano_last_step < 60) return true;
            // The small rolling checks already cover the whole idle map within
            // 60 steps. Do not rescan all 6,400 cells on the clock's redraw frame.
            thor_nano_clock_only = true;
        }
    }
    thor_nano_previous = true;
    thor_nano_dirty = false;
    thor_nano_last_step = thor_steps;
    thor_nano_last_health = global.playerhealth;
    thor_nano_last_ammo = global.missiles;
    thor_nano_last_super = global.smissiles;
    thor_nano_last_bombs = global.pbombs;
    thor_nano_last_weapon = global.currentweapon;
    thor_nano_last_time = _clock_second;
    thor_nano_last_items = global.itemstaken;
    thor_nano_last_monsters = global.monstersleft;
    thor_nano_last_area = global.monstersarea;
    thor_nano_last_cell_x = _cell_x;
    thor_nano_last_cell_y = _cell_y;
    return false;
}

function thor_nano_map_changed() {
    var _cache = thor_map_columns_cache;
    if (!thor_map_valid || !_cache.ready) return true;
    // Two columns, then one, then one: 80 columns in 60 idle frames,
    // retaining the old scan budget without concentrating it into one frame.
    var _columns = (thor_nano_poll_column mod 4 == 0) ? 2 : 1;
    for (var _i = 0; _i < _columns; ++_i) {
        var _x = thor_nano_poll_column;
        thor_nano_poll_column = (_x + 1) mod 80;
        // Keep snapshots untouched: the full refresh still needs to discover
        // and repaint these edits. Item, health and cell changes bypass this.
        if (!array_equals(_cache.seen[_x], global.dmap[_x])
            || !array_equals(_cache.tiles[_x], global.map[_x])) return true;
    }
    return false;
}

/// @description Compose lower output, respecting the existing per-step guard.
/// @context oControl
function thor_draw() {
    // Compose once per game step even when an earlier draw route already submitted it.
    if (thor_lower_step == thor_steps) return;
    thor_lower_step = thor_steps;
    if (!thor_enabled) exit;
    var _escape = noone;
    if (instance_exists(oA4EscapeExplosion)) _escape = instance_find(oA4EscapeExplosion, 0);
    if (instance_exists(oA4EscapeExplosionFail)) _escape = instance_find(oA4EscapeExplosionFail, 0);
    var _room_changed = thor_output_room != room;
    // Submit each game frame so scrolling and touch panning keep the upper display's cadence.
    // Capture the last lower image before a transition room replaces its contents.
    if (_room_changed && room == rm_transition && surface_exists(thor_surface)) {
        if (!surface_exists(thor_room_surface)) thor_room_surface = surface_create(thor_width, thor_height);
        surface_copy(thor_room_surface, 0, 0, thor_surface);
    }
    thor_output_room = room;

    var _frontend = thor_frontend_mode();
    var _game = _frontend == THOR_FRONTEND_GAMEPLAY && variable_global_exists("map") && variable_global_exists("mapposx")
        && (global.ingame || room == rm_subscreen || room == rm_transition || room == itemroom || room == rm_death);
    var _cell_x = _game ? global.mapposx : -1;
    var _cell_y = _game ? global.mapposy : -1;
    var _paused = room == rm_subscreen;
    var _ui_paused = _paused && (!instance_exists(oSS_Fg) || !oSS_Fg.fadeout);
    var _pause_map = _ui_paused && global.ssmode == 0 && !instance_exists(oSubScrChange);
    // When gameplay becomes available, reset map caches and return to following the player.
    if (_game && !thor_had_game) {
        thor_follow = true;
        thor_overview = false;
        thor_zoom = 1;
        thor_manual_zoom = 1;
        thor_next_map = 0;
        thor_map_valid = false;
        // Clear each field separately so the first map frame has no old area to fade from.
        thor_backdrop = -1;
        thor_backdrop_previous = -1;
        thor_lab_entrance = false;
        thor_previous_lab_entrance = false;
        thor_research_site = false;
        thor_previous_research_site = false;
        thor_waterfalls = false;
        thor_previous_waterfalls = false;
        thor_backdrop_room = -1;
    }
    thor_had_game = _game;

    var _nano_eligible = _game && global.ingame && global.enablecontrol && !_paused
        && !_room_changed && !thor_setup_needed && _escape == noone
        && room != rm_transition && room != rm_loading && room != itemroom && room != rm_death
        && current_time >= thor_transition_until && thor_room_alpha >= 1
        && (thor_backdrop_previous < 0 || current_time >= thor_backdrop_since + 600);
    if (thor_nano_reuse(_nano_eligible, _cell_x, _cell_y)) return;

    if (_game) {
        thor_update_backdrop();
        thor_art_geometry();
        if (thor_overview) {
            thor_center_x = (thor_map_min_x + thor_map_max_x) / 2;
            thor_center_y = (thor_map_min_y + thor_map_max_y) / 2;
            thor_zoom = thor_map_fit_zoom();
        }
        if (thor_follow) {
            // Exactly the minimap's integer cell, including room map offsets.
            thor_center_x = _cell_x + 0.5;
            thor_center_y = _cell_y + 0.5;
        }
        if (_pause_map && thor_marker_pan && global.mapmarker) {
            // Keep controller-edited markers visible without moving a touch-browsed map.
            var _half_x = (thor_width - 20) / (16 * thor_zoom);
            var _half_y = (thor_map_bottom - thor_map_top - 20) / (16 * thor_zoom);
            thor_center_x = clamp(thor_center_x, global.mapmarkerx + 0.5 - _half_x, global.mapmarkerx + 0.5 + _half_x);
            thor_center_y = clamp(thor_center_y, global.mapmarkery + 0.5 - _half_y, global.mapmarkery + 0.5 + _half_y);
        }
        thor_center_x = clamp(thor_center_x, 0, 80);
        thor_center_y = clamp(thor_center_y, 0, 80);
    }

    // Save the caller's font, color, alpha, and alignment before composing a frame for the ready presentation.
    if (Thor_Ready()) {
        var _font = draw_get_font(), _color = draw_get_color(), _alpha = draw_get_alpha();
        var _ha = draw_get_halign(), _va = draw_get_valign();
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        var _menu_key = _ui_paused ? (instance_exists(oSubScrChange) ? 4 : global.ssmode) : -1;
        if (!surface_exists(thor_surface)) {
            thor_surface = surface_create(thor_width, thor_height);
            thor_menu_key = _menu_key;
            thor_ui_paused = _ui_paused;
            thor_transition_until = 0;
        }
        if (_menu_key != thor_menu_key) {
            thor_art_snapshot();
            if (!surface_exists(thor_transition_surface)) thor_transition_surface = surface_create(thor_width, thor_height);
            // Blend from the actual last lower frame, including an interrupted fade.
            surface_copy(thor_transition_surface, 0, 0, thor_surface);
            thor_transition_kind = _ui_paused == thor_ui_paused ? 0 : (_ui_paused ? 1 : 2);
            thor_menu_key = _menu_key;
            thor_ui_paused = _ui_paused;
            thor_transition_until = current_time + 160;
        }
        thor_art_prepare(_game, _frontend, _ui_paused, _pause_map);
        // Reuse a fixed pixel-transfer buffer and lazily create the grid and map surfaces.
        if (!buffer_exists(thor_buffer)) thor_buffer = buffer_create(thor_width * thor_height * 4, buffer_fixed, 1);
        if (!surface_exists(thor_grid)) {
            thor_grid = effect_surface_create(192, 192);
            surface_set_target(thor_grid);
            draw_clear(c_black);
            for (var _gx = 0; _gx < 192; _gx += 24) {
                for (var _gy = 0; _gy < 192; _gy += 24) draw_background(bgMapScreenBG, _gx, _gy);
            }
            surface_reset_target();
        }
        if (!surface_exists(thor_map)) {
            thor_map = effect_surface_create(640, 640);
            thor_map_valid = false;
            thor_next_map = 0;
        }
        if (_game && !thor_nano_clock_only
            && (current_time >= thor_next_map || _cell_x != thor_last_cell_x || _cell_y != thor_last_cell_y)) {
            thor_next_map = current_time + 250;
            thor_last_cell_x = _cell_x;
            thor_last_cell_y = _cell_y;
            // Poll the original data, including item and monster changes made by
            // existing objects. Repaint only when visible tile content has changed.
            if (thor_map_columns_changed()) thor_map_repaint_cached_columns();
        }
        if (_game) thor_compact_map_update();

        // Retain the pre-death lower image, then draw the active setup, menu, transition, or gameplay panel.
        thor_frontend_snapshot(_frontend);
        surface_set_target(thor_surface);
        draw_clear(c_black);
        var _lower_matrix = matrix_get(matrix_world);
        matrix_set(matrix_world, matrix_build(thor_pad, 0, 0, 0, 0, 0, 1, 1, 1));
        draw_set_font(fontMenuSmall);
        if (thor_setup_needed) {
            if (thor_setup_stage == 1) {
                matrix_set(matrix_world, matrix_build_identity());
                thor_setup_draw_page(false);
            } else if (surface_exists(thor_setup_surface)) {
                draw_surface(thor_setup_surface, -5, floor((thor_height - 240) / 2));
            }
        } else if (room == rm_transition) {
            // Keep the map visible between game rooms; retain fades for loading and Game Over.
            if (!thor_loading_transition && surface_exists(thor_room_surface) && instance_exists(oTransition)) {
                draw_surface_ext(thor_room_surface, -thor_pad, 0, 1, 1, 0, c_white,
                    thor_keep_room_map ? 1 : 1 - clamp(oTransition.fade, 0, 1));
            }
        } else if (room == rm_loading) {
            // Loading can replace rooms before they have produced their first image.
            // Both panels remain black until the destination begins its fade-in.
        } else if (thor_draw_frontend_lower(_frontend)) {
            // The shared scene owns these panels; gameplay chrome stays hidden.
        } else if (_ui_paused && !_pause_map && surface_exists(application_surface)) {
            // Trim only the five-pixel side margins; resampling the 320-pixel page
            // into 310 pixels deletes columns from lettering and equipment artwork.
            // The original page has flat border pixels outside its artwork.
            // Extend those columns on wider panels, including their exact bar
            // positions and fade, without resampling the text or illustrations.
            var _page_margin = (thor_width - surface_get_width(application_surface)) / 2;
            if (_page_margin > 0) {
                var _page_height = surface_get_height(application_surface);
                draw_surface_part_ext(application_surface, 0, 0, 1, _page_height,
                    -thor_pad, thor_page_y, _page_margin, 1, c_white, 1);
                draw_surface_part_ext(application_surface, surface_get_width(application_surface) - 1, 0, 1, _page_height,
                    315, thor_page_y, _page_margin, 1, c_white, 1);
            }
            draw_surface(application_surface, -5, thor_page_y);
            if (thor_art_footer_rows > 0) {
                draw_set_color(c_black);
                draw_rectangle(-thor_pad, thor_art_page_controls_top(),
                    310 + thor_pad, thor_height, false);
                thor_draw_artwork_footer(-thor_pad, 0, thor_width);
            }
            if (!instance_exists(oSubScrChange)) {
                thor_toolbar_button(thor_action_buttons[0], "SELECT", false, thor_art_page_controls_top(), thor_height - 1, get_button_sprite("Menu1"));
                thor_toolbar_button(thor_action_buttons[1], "MENU", false, thor_art_page_controls_top(), thor_height - 1, get_button_sprite("Menu2"));
            }
            thor_toolbar_button(thor_action_buttons[2], "RESUME", false, thor_art_page_controls_top(), thor_height - 1, get_button_sprite("Start"));
        } else if (_game) {
            var _ox = round(155 - thor_center_x * 8 * thor_zoom);
            var _oy = round((thor_map_top + thor_map_bottom) / 2 - thor_center_y * 8 * thor_zoom);
            thor_draw_map_base(_ox, _oy);
            var _marker_scale = max(0.75, thor_zoom);
            draw_sprite_ext(sMapHilight, 0, round(_ox + (_cell_x + 0.5) * 8 * thor_zoom - 4 * _marker_scale),
                round(_oy + (_cell_y + 0.5) * 8 * thor_zoom - 4 * _marker_scale),
                _marker_scale, _marker_scale, 0, c_white, global.nano_enabled && !_paused ? 0.8 : 0.55 + 0.35 * sin(current_time / 250));
            if (global.mapmarker) {
                var _marker_x = round(_ox + (global.mapmarkerx + 0.5) * 8 * thor_zoom - 4 * _marker_scale);
                var _marker_y = round(_oy + (global.mapmarkery + 0.5) * 8 * thor_zoom - 4 * _marker_scale);
                draw_sprite_ext(sMapMarker, global.nano_enabled && !_paused ? 0 : markfr, _marker_x, _marker_y, _marker_scale, _marker_scale, 0, c_white, 1);
                if (_pause_map && instance_exists(oMapCursor) && oMapCursor.state == 1) {
                    draw_sprite_ext(sMapMarkerMove, markfr, _marker_x, _marker_y, _marker_scale, _marker_scale, 0, c_white, 1);
                }
            }
            // Reserve the chosen HUD height above the map and one context-sensitive toolbar below it.
            draw_set_color(c_black);
            draw_rectangle(-thor_pad, 0, 310 + thor_pad, thor_map_top - 1, false);
            draw_rectangle(-thor_pad, thor_map_bottom, 310 + thor_pad, thor_height, false);
            thor_draw_artwork_status(-thor_pad, 0, thor_width);
            thor_draw_artwork_footer(-thor_pad, thor_map_bottom, thor_width);
            draw_set_font(fontMenuSmall);
            // Fanfare and scripted scenes keep their original input locks.
            draw_set_alpha(_paused || (global.ingame && global.enablecontrol && room != rm_transition) ? 1 : 0.4);
            if (_pause_map) {
                var _editing = instance_exists(oMapCursor) && oMapCursor.state == 1;
                var _marker = _editing ? "DONE" : (global.mapmarker ? "EDIT" : "MARKER");
                thor_toolbar_button(thor_action_buttons[0], _marker, false, thor_art_map_controls_top(), thor_height - 1, get_button_sprite("Menu1"));
                thor_toolbar_button(thor_action_buttons[1], _editing ? "DELETE" : "MENU", false, thor_art_map_controls_top(), thor_height - 1, get_button_sprite("Menu2"));
                thor_toolbar_button(thor_action_buttons[2], "UNPAUSE", false, thor_art_map_controls_top(), thor_height - 1, get_button_sprite("Start"));
            } else {
                thor_toolbar_button(thor_map_buttons[0], "+", false);
                thor_toolbar_button(thor_map_buttons[1], "-", false);
                thor_toolbar_button(thor_map_buttons[2], "1x", false);
                thor_toolbar_button(thor_map_buttons[3], "FIT MAP", thor_overview);
                thor_toolbar_button(thor_map_buttons[4], "FOLLOW", thor_follow);
            }
            draw_set_alpha(1);
        }
        // Return to the original drawing transform before blending whole-panel transitions and fades.
        matrix_set(matrix_world, _lower_matrix);
        var _old_alpha = clamp((thor_transition_until - current_time) / 160, 0, 1);
        if (thor_transition_kind == 1) _old_alpha = _ui_paused ? 1 - thor_pause_blend() : 0;
        if (thor_transition_kind == 2) _old_alpha = _paused ? thor_pause_blend() : 0;
        if (room != rm_transition && room != rm_loading && _frontend == THOR_FRONTEND_GAMEPLAY
            && _old_alpha > 0 && surface_exists(thor_transition_surface)) {
            draw_surface_ext(thor_transition_surface, 0, 0, 1, 1, 0, c_white, _old_alpha);
        }
        if (!thor_setup_needed && !thor_keep_room_map && room != rm_transition && thor_room_alpha < 1) {
            draw_set_color(c_black);
            draw_set_alpha(1 - thor_room_alpha);
            draw_rectangle(0, 0, thor_width, thor_height, false);
            draw_set_alpha(1);
        }
        // Both panels follow the reactor's existing white flash, including a failed escape.
        if (_escape != noone) {
            var _mode = gpu_get_blendmode();
            gpu_set_blendmode(bm_add);
            draw_set_color(c_white);
            // The blast brightens gameplay before the white fade starts; mirror that glow below too.
            if (!_escape.fadeout) {
                var _camera = widescreen ? 1 : 0;
                var _sx = thor_width / __view_get(e__VW.WView, _camera);
                var _sy = thor_height / __view_get(e__VW.HView, _camera);
                var _x = (_escape.x - __view_get(e__VW.XView, _camera)) * _sx;
                var _y = (_escape.y - __view_get(e__VW.YView, _camera)) * _sy;
                var _xs = _escape.image_xscale * _sx, _ys = _escape.image_yscale * _sy;
                var _sprite = _escape.sprite_index, _frame = _escape.image_index;
                draw_sprite_ext(_sprite, _frame, _x, _y, _xs, _ys, _escape.image_angle, c_white, _escape.image_alpha);
                draw_sprite_ext(_sprite, _frame, _x, _y, -_xs, _ys, _escape.image_angle, c_white, _escape.image_alpha);
                draw_sprite_ext(_sprite, _frame, _x, _y, -_xs, -_ys, _escape.image_angle, c_white, _escape.image_alpha);
                draw_sprite_ext(_sprite, _frame, _x, _y, _xs, -_ys, _escape.image_angle, c_white, _escape.image_alpha);
            }
            draw_set_alpha(clamp(_escape.whitealpha, 0, 1));
            draw_rectangle(0, 0, thor_width, thor_height, false);
            gpu_set_blendmode(_mode);
            draw_set_alpha(1);
        }
        // Capture the lower target before its normal reset flushes drawing.
        var _gpu = thor_art_gpu(), _swap = thor_swap_active();
        if (_gpu && !_swap) Thor_GPU(0, thor_width, thor_height);
        surface_reset_target();
        if (_gpu) thor_art_finish(_old_alpha, _frontend, _escape);
        var _gpu_sent = false;
        if (_swap) {
            // The final GUI End event sends the complete gameplay image instead.
            // Retain this native map and its separate full-resolution HUD for the runner.
            _gpu_sent = true;
        } else if (_gpu) {
            _gpu_sent = Thor_GPU(1, thor_width, thor_height) > 0;
        } else Thor_GPU(2, thor_width, thor_height);
        // An unsupported or unavailable GPU path always falls back to the existing output.
        if (!_gpu_sent) {
            if (_gpu) thor_art_fallback();
            buffer_get_surface(thor_buffer, thor_surface, 0);
            Thor_Frame(thor_buffer);
        }
        // Count calls to the frame bridge here; Android records bitmap updates separately.
        if (!_swap) thor_frames++;
        draw_set_font(_font); draw_set_color(_color); draw_set_alpha(_alpha);
        draw_set_halign(_ha); draw_set_valign(_va);
    } else {
        // A recreated Android presentation may become ready on a later frame.
        thor_nano_dirty = true;
    }
}

// Release oControl's drawing surfaces and transfer buffer when its Cleanup event runs.
/// @description Release display surfaces, buffers and cached controller images.
/// @context oControl
function thor_cleanup() {
    if (surface_exists(thor_map_base)) surface_free(thor_map_base);
    thor_map_base_key = [];
    thor_art_reset_images();
    if (surface_exists(thor_upper_hud_surface)) surface_free(thor_upper_hud_surface);
    if (buffer_exists(thor_upper_hud_buffer)) buffer_delete(thor_upper_hud_buffer);
    if (surface_exists(thor_pause_surface)) surface_free(thor_pause_surface);
    if (surface_exists(thor_setup_surface)) surface_free(thor_setup_surface);
    if (surface_exists(thor_scene)) surface_free(thor_scene);
    if (surface_exists(thor_room_surface)) surface_free(thor_room_surface);
    if (surface_exists(thor_death_surface)) surface_free(thor_death_surface);
    if (surface_exists(thor_surface)) surface_free(thor_surface);
    if (surface_exists(thor_map)) surface_free(thor_map);
    if (surface_exists(thor_map_column)) surface_free(thor_map_column);
    if (surface_exists(thor_compact_strip)) surface_free(thor_compact_strip);
    if (surface_exists(thor_compact_map)) surface_free(thor_compact_map);
    if (surface_exists(thor_grid)) surface_free(thor_grid);
    if (surface_exists(thor_hud_sheet)) surface_free(thor_hud_sheet);
    if (surface_exists(thor_art_hold)) surface_free(thor_art_hold);
    if (surface_exists(thor_art_surface)) surface_free(thor_art_surface);
    if (thor_art_help_font >= 0) font_delete(thor_art_help_font);
    if (surface_exists(thor_transition_surface)) surface_free(thor_transition_surface);
    if (buffer_exists(thor_buffer)) buffer_delete(thor_buffer);
}
