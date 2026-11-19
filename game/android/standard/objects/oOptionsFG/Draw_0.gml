// Title/options help keeps the English geometry for every language.
var _x = __view_get(e__VW.XView, 0), _y = __view_get(e__VW.YView, 0);
draw_set_alpha(1); draw_set_color(c_black);
draw_rectangle(_x, _y + 230, _x + 322, _y + 245, false);
port_draw_help_text(_x + 160, _y + 230, 304, 16, fontMenuSmall);
