// The player's last activation rectangle already covers nearby terrain. Use
// that exact rectangle, not the moving camera, until the next culling pass.
var _covered = global.enemy_activation_room == room
    && x - 16 >= global.enemy_activation_left && x + 16 <= global.enemy_activation_right
    && y - 16 >= global.enemy_activation_top && y + 16 <= global.enemy_activation_bottom;
// Outside it, a stationary crab only needs another query after world culling.
// Movement always invalidates this exact-position cache.
if (!_covered && (activation_epoch != global.enemy_activation_epoch || x != activation_x || y != activation_y)) {
    instance_activate_region(x - 16, y - 16, 32, 32, 1);
    activation_epoch = global.enemy_activation_epoch;
    activation_x = x;
    activation_y = y;
}
