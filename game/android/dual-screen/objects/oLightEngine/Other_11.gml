if (nano_light_update()) exit;
var lum, col;
var widescreen = oControl.widescreen;
// All glows in this pass share the same camera snapshot.
var _light_view_x = __view_get(e__VW.XView, widescreen);
var _light_view_y = __view_get(e__VW.YView, widescreen);
// GM2026/Android fix: surfaces are volatile — freed when the app is backgrounded. Step_0 calls
// this event every step with no guard (Draw_0 and Step_2 do guard), so the first frame after the
// app regains focus targeted a freed surface -> FATAL "surface target does not exist" (repro:
// pause to map, leave app, return, unpause). Recreate to match Other_10 before targeting.
if (!surface_exists(surf)) surf = effect_surface_create(512, 256);
surface_set_target(surf);
// Rebuild a darkness mask: each light removes brightness from the mask at its view-relative position.
draw_clear(c_white);
draw_set_blend_mode(bm_subtract);
draw_set_alpha(1);
draw_set_color(make_color_hsv(0, 0, 1));
draw_rectangle(0, 0, 330*2, 250, false); // just 330 pre-widescreen
with (oLight) {
    image_blend = make_color_hsv(0, 0, image_alpha * 255);
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = image_blend;
    var _light_xscale = image_xscale;
    var _light_yscale = image_yscale;
    light_draw_quad(sprite_index, -1, _light_x, _light_y, _light_xscale, _light_yscale, _light_color, 1);
}
with (oBeam) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = image_blend;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, _light_color, 1);
}
with (oMissile) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = image_blend;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, _light_color, 1);
}
with (oBomb) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = image_blend;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.25, 0.25, _light_color, 1);
}
with (oBomb2) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = image_blend;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.25, 0.25, _light_color, 1);
}
with (oPickup) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = image_blend;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.25, 0.25, _light_color, 1);
}
if (global.nano_enabled) {
    draw_set_blend_mode(bm_normal);
    surface_reset_target();
    exit;
}
with (oMGammaElec) draw_sprite_ext(sGElectLight, -1, x - _light_view_x, y - _light_view_y, 1, 1, image_angle, image_blend, 1);
with (oGlowPlant1) {
    var _light_x = x - _light_view_x;
    var _light_y = y - 16 - _light_view_y;
    var _light_color = make_color_rgb(100, 100, 250);
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.65, 0.65, _light_color, 1);
}
with (oSpikePlant) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = make_color_rgb(150, 150, 60);
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.4, 0.4, _light_color, 1);
}
with (oPincherFly) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = make_color_rgb(120, 80, 30);
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.3, 0.3, _light_color, 1);
}
with (oA3LabLight) if (image_index == 0) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = make_color_rgb(230, 230, 130);
    light_draw_quad(sLight0, -1, _light_x, _light_y, 1.4, 1.4, _light_color, 1);
}
with (oA3LabDoor) {
    var _light_x = x - _light_view_x;
    var _light_y = y + 32 - _light_view_y;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 1, 0.4, c_white, 1);
}
with (oFXAnimSpark) if (sprite_index == sExpl1 || sprite_index == sExpl2) {
    lum = 1 - image_index / 11 * 220 + 35;
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = make_color_rgb(lum, lum, lum);
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, _light_color, 1);
}
with (oLightBug) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.25, 0.25, c_white, 1);
}
with (oChargeBeamSpark1) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = image_blend;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, _light_color, 1);
}
with (oItemBall) {
    var _light_x = x + 8 - _light_view_x;
    var _light_y = y - 8 - _light_view_y;
    var _light_color = image_blend;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, _light_color, 1);
}
with (oItem) {
    var _light_x = x + 8 - _light_view_x;
    var _light_y = y - 8 - _light_view_y;
    var _light_color = image_blend;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, _light_color, 1);
}
with (oDoor) {
    var _light_x = x - _light_view_x;
    var _light_y = y + 32 - _light_view_y;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 1, 0.4, c_white, 1);
}
with (oMOmegaFlame) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_color = image_blend;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.75, 0.75, _light_color, 1);
}
with (oMOmega_Projectile) {
    var _light_x = x - _light_view_x;
    var _light_y = y + 16 - _light_view_y;
    var _light_color = image_blend;
    var _light_alpha = image_alpha;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 1, 1, _light_color, _light_alpha);
}
with (oA8Lamp) {
    var _light_x = x - _light_view_x;
    var _light_y = y + 4 - _light_view_y;
    var _light_color = image_blend;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, _light_color, 1);
    draw_sprite_ext(sA8Light, -1, x - _light_view_x, y - _light_view_y, 2, 1, 0, image_blend, 1);
    draw_sprite_ext(sA8Light, -1, x - _light_view_x, y - _light_view_y, -2, 1, 0, image_blend, 1);
}
with (oA8RedLight) {
    col = make_color_rgb(image_alpha * 255, 0, 0);
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    var _light_alpha = image_alpha;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 1, 1, col, _light_alpha);
}
with (oA6Dust) {
    col = make_color_rgb(image_alpha * 133, image_alpha * 189, image_alpha * 136);
    var _light_x = round(x - _light_view_x);
    var _light_y = round(y - _light_view_y);
    var _light_alpha = image_alpha;
    light_draw_quad(sLight0, -1, _light_x, _light_y, scale * 1.2, scale * 1.2, col, _light_alpha);
}
with (oA8RedLightFX) draw_background_ext(bgWhite, 0, 0, 20, 20, 0, image_blend, image_alpha);
with (oGenesisAcid) {
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.25, 0.25, c_lime, 1);
}
with (oGenesisSlashProj) {
    col = make_color_rgb(0, image_alpha * 255, 0);
    var _light_x = x - _light_view_x;
    var _light_y = y - _light_view_y;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, col, 1);
}
with(oElderSeptogg) {
    if(flying_sprite == sElderSeptogg_tlArea3Breed) {
        var _light_x = xstart - _light_view_x;
        var _light_y = y + yy + 21 - _light_view_y;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, c_orange, 0.8);
    }
}
//X Parasite glows
with (oXPickup) {
    if(xtype = sHXPickup) {
        var _light_x = x - _light_view_x;
        var _light_y = y - _light_view_y;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.3, 0.3, c_yellow, 1);
    }
    else if(xtype = sMXPickup) {
        var _light_x = x - _light_view_x;
        var _light_y = y - _light_view_y;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.3, 0.3, c_lime, 1);
    }
    else if(xtype = sSMXPickup) {
        var _light_x = x - _light_view_x;
        var _light_y = y - _light_view_y;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.3, 0.3, c_orange, 1);
    }
    else if(xtype = sPBXPickup) {
        var _light_x = x - _light_view_x;
        var _light_y = y - _light_view_y;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.3, 0.3, c_red, 1);
    }
}
with (oCoreX) {
    if(sprite_index == sCoreXGenesis) {
        var purple_glow = max(0, glow);
        col = make_color_rgb(purple_glow * 255, purple_glow * 109, purple_glow * 245);
        var _light_x = x - _light_view_x;
        var _light_y = y - _light_view_y;
        var _light_alpha = purple_glow;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, col, _light_alpha);
        
        var green_glow = max(0, glow*-1);
        col = make_color_rgb(green_glow * 24, green_glow * 229, green_glow * 60);
        var _light_x = x - _light_view_x;
        var _light_y = y - _light_view_y;
        var _light_alpha = green_glow;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.5, 0.5, col, _light_alpha);
        
        if(!instance_exists(oCoreXShell) && (state == 0 || state == 1)) {
            draw_sprite_ext(sCoreXAura, -1, x - _light_view_x, y - _light_view_y, 1, 1, image_angle, image_blend, drawaura);
        }
        
        with(oElectricSparkCoreX) {
            col = make_color_rgb(image_alpha * 72, image_alpha * 208, image_alpha * 232);
            var _light_x = x - _light_view_x;
            var _light_y = y - _light_view_y;
            var _light_alpha = image_alpha;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.75, 0.75, col, _light_alpha);
        }
        with(oElectricSparkCoreXShort) {
            col = make_color_rgb(image_alpha * 72, image_alpha * 208, image_alpha * 232);
            var _light_x = x - _light_view_x;
            var _light_y = y - _light_view_y;
            var _light_alpha = image_alpha;
    light_draw_quad(sLight0, -1, _light_x, _light_y, 0.75, 0.75, col, _light_alpha);
        }
    }
}
//End X Parasite Glows

draw_set_blend_mode(bm_normal);
surface_reset_target();

