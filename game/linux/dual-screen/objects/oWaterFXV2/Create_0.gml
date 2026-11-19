FREQ = 8;
AMP = 2;
SPEED = 0.05;
THETA = 0;
y_bottom = y - __view_get( e__VW.YView, 0 );
if (y_bottom < 0) y_bottom = 0;
if (y_bottom > __view_get( e__VW.HView, 0 )) y_bottom = __view_get( e__VW.HView, 0 );
mysurf = surface_create(320 + (oControl.widescreen*oControl.widescreen_space), 240);


water_mesh = -1; water_format = -1;
water_mesh_height = -1; water_mesh_top = -1; water_mesh_bottom = -1;
water_mesh_width = -1; water_mesh_sw = -1; water_mesh_sh = -1; water_mesh_tail = -1;
water_offsets = array_create(240, 0);

water_uniform_shader = -1;
