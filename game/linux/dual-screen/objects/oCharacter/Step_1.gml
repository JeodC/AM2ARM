/// @description  Activation/deactivation
// Periodically refresh active objects around the view and Samus; Alarm 11 requests the next refresh.
if(activation_code) {
    global.enemy_activation_epoch++;
    instance_activate_region(__view_get( e__VW.XView, 0 ) - 300, __view_get( e__VW.YView, 0 ) - 300, __view_get( e__VW.WView, 0 ) + 600, __view_get( e__VW.HView, 0 ) + 600, 1);
    if (global.objdeactivate) instance_deactivate_object(oSolid);
    instance_activate_object(oMovingSolid);
    if (global.objdeactivate) instance_deactivate_object(oEnemy);
    instance_deactivate_object(oGotoRoom);
    global.enemy_activation_room = room;
    global.enemy_activation_left = __view_get(e__VW.XView, 0) - 200;
    global.enemy_activation_top = __view_get(e__VW.YView, 0) - 200;
    global.enemy_activation_right = global.enemy_activation_left + __view_get(e__VW.WView, 0) + 400;
    global.enemy_activation_bottom = global.enemy_activation_top + __view_get(e__VW.HView, 0) + 400;
    instance_activate_region(global.enemy_activation_left, global.enemy_activation_top,
        global.enemy_activation_right - global.enemy_activation_left,
        global.enemy_activation_bottom - global.enemy_activation_top, 1);
    instance_activate_region(x - 64, y - 64, 128, 128, 1);
    // Nano pauses distant crabs like other enemies; nearby crabs still run every step.
    if (!global.nano_enabled || !global.objdeactivate) instance_activate_object(oGravitt);
    
    activation_code = false;
}

