// Reuse strip geometry; the vertex shader moves each entire strip together.
function water_mesh_vertex(_x, _y, _u, _v, _row) {
    vertex_position(water_mesh, _x, _y);
    vertex_colour(water_mesh, make_color_rgb(_row, 255, 255), 0.2);
    vertex_texcoord(water_mesh, _u, _v);
}
function water_mesh_quad(_top, _height, _dest_y, _row, _width, _sw, _sh) {
    // Match the runner: out-of-range surface coordinates keep their geometry.
    var _w = _width, _h = _height;
    if (_w <= 0 || _h <= 0) return;
    var _u = _w / _sw, _v0 = _top / _sh, _v1 = (_top + _h) / _sh;
    // Keep the runner's quad diagonal and vertex order for interpolation parity.
    water_mesh_vertex(0, _dest_y, 0, _v0, _row);
    water_mesh_vertex(_w, _dest_y, _u, _v0, _row);
    water_mesh_vertex(_w, _dest_y + _h, _u, _v1, _row);
    water_mesh_vertex(_w, _dest_y + _h, _u, _v1, _row);
    water_mesh_vertex(0, _dest_y + _h, 0, _v1, _row);
    water_mesh_vertex(0, _dest_y, 0, _v0, _row);
}
function water_draw_batch(_x, _y, _width, _height_top) {
    var _cheap=global.nano_enabled;
    var _shader=_cheap ? shNanoWater : shWaterStrips;
    if (!shader_is_compiled(_shader) || shader_current() != -1 || y_bottom <= 0) return false;
    // At the bottom edge the visible water height is zero. Let the existing
    // strip path handle that no-op instead of freezing an empty vertex buffer.
    if (_height_top <= 0) return false;
    // Geometry can be shared across modes, but uniform handles belong to a shader.
    if (water_uniform_shader != _shader) {
        water_wave_uniform = shader_get_uniform(_shader, _cheap ? "uWave" : "uOffsets");
        water_offset_uniform = shader_get_uniform(_shader, "uOffset");
        water_uniform_shader = _shader;
    }
    var _sw = surface_get_width(mysurf), _sh = surface_get_height(mysurf);
    var _height = global.wave_height;
    var _tail = _height_top < _height ? y - _y : 0;
    if (water_mesh < 0 || water_mesh_height != _height || water_mesh_top != y_top
        || water_mesh_bottom != y_bottom || water_mesh_width != _width
        || water_mesh_sw != _sw || water_mesh_sh != _sh || water_mesh_tail != _tail) {
        if (water_mesh >= 0) vertex_delete_buffer(water_mesh);
        if (water_format < 0) {
            vertex_format_begin();vertex_format_add_position();
            vertex_format_add_colour();vertex_format_add_texcoord();
            water_format = vertex_format_end();
        }
        water_mesh = vertex_create_buffer();vertex_begin(water_mesh, water_format);
        var _row;
        for (_row=0;_row<240;_row+=_height) {
            if (_row >= y_top) {
                water_mesh_quad(_row, _height, _row, _row, _width, _sw, _sh);
                if (_row-y_top < _height)
                    water_mesh_quad(y_top, _row-y_top, y_top, _row, _width, _sw, _sh);
            }
        }
        if (_height_top < _height)
            water_mesh_quad(y_top, _height_top, _tail, _row-_height, _width, _sw, _sh);
        vertex_end(water_mesh);vertex_freeze(water_mesh);
        water_mesh_height=_height;water_mesh_top=y_top;water_mesh_bottom=y_bottom;
        water_mesh_width=_width;water_mesh_sw=_sw;water_mesh_sh=_sh;water_mesh_tail=_tail;
    }
    if (_cheap) {
        // Preserve observable loop state while evaluating wave offsets on the GPU.
        yy=ceil(240/_height)*_height;
        xx=AMP*sin(THETA+FREQ*(yy-_height)/y_bottom);
        shader_set(_shader);
        shader_set_uniform_f(water_wave_uniform,THETA,AMP,FREQ/y_bottom,_x-oControl.widescreen_space/2);
    } else {
        for (yy=0;yy<240;yy+=_height) {
            xx=AMP*sin(THETA+FREQ*yy/y_bottom);
            water_offsets[yy]=_x+xx-oControl.widescreen_space/2;
        }
        shader_set(_shader);
        shader_set_uniform_f_array(water_wave_uniform,water_offsets);
    }
    shader_set_uniform_f(water_offset_uniform,0,_y);
    vertex_submit(water_mesh,pr_trianglelist,surface_get_texture(mysurf));
    shader_reset();return true;
}
