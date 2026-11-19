/* App-private second Wayland output; included beside the original probe state. */
#include <math.h>
#define PUBLIC __attribute__((visibility("default")))
static struct wl_surface *lower_surface;
static struct xdg_surface *lower_xdg;
static struct xdg_toplevel *lower_top;
static struct wl_egl_window *lower_window;
static int lower_configured, lower_width=640, lower_height=480;
static struct wl_seat *input_seat;
static struct wl_touch *input_touch;
static struct { int id, active, from_gameplay; double x,y; } contacts[2];
static double drag_x,drag_y,zoom_delta,touch_x,touch_y,origin_x,origin_y,last_span;
static int tapped, moved;
static unsigned long touch_events;
static int routed_reverse, requested_reverse;
PUBLIC int am2r_native_route(int reverse);

static void lower_configure(void *data, struct xdg_surface *s, uint32_t serial) {
    (void)data; xdg_surface_ack_configure(s,serial); lower_configured=1;
}
static const struct xdg_surface_listener lower_surface_listener={.configure=lower_configure};
static void lower_size(void *data, struct xdg_toplevel *t, int32_t w,int32_t h,struct wl_array *states) {
    (void)data;(void)t;(void)states;
    if(w>0 && h>0) { lower_width=w;lower_height=h;
        if(lower_window) wl_egl_window_resize(lower_window,w,h,0,0);
    }
}
static const struct xdg_toplevel_listener lower_top_listener={.configure=lower_size,.close=close_toplevel};
PUBLIC void *am2r_native_lower_window(void) {
    if(lower_window)return lower_window;
    if(!native_probe_wayland_display() || output_count<2)return NULL;
    lower_surface=wl_compositor_create_surface(compositor);
    wl_surface_add_listener(lower_surface,&output_listener,NULL);
    lower_xdg=xdg_wm_base_get_xdg_surface(shell,lower_surface);
    xdg_surface_add_listener(lower_xdg,&lower_surface_listener,NULL);
    lower_top=xdg_surface_get_toplevel(lower_xdg);
    xdg_toplevel_add_listener(lower_top,&lower_top_listener,NULL);
    xdg_toplevel_set_title(lower_top,"AM2R map and menus");
    xdg_toplevel_set_app_id(lower_top,"am2r.native.lower");
    xdg_toplevel_set_fullscreen(lower_top,outputs[1]);
    wl_surface_commit(lower_surface);
    for(int n=0;!lower_configured && n<10;n++)
        if(wl_display_roundtrip(display)<0)return NULL;
    if(!lower_configured)return NULL;
    lower_window=wl_egl_window_create(lower_surface,lower_width,lower_height);
    fprintf(stderr,"NATIVE_LOWER window %dx%d output 1\n",lower_width,lower_height);
    if(requested_reverse)am2r_native_route(requested_reverse);
    return lower_window;
}
PUBLIC int am2r_native_lower_width(void){return lower_width;}
PUBLIC int am2r_native_lower_height(void){return lower_height;}
PUBLIC int am2r_native_route(int reverse) {
    requested_reverse=reverse!=0;
    if(!toplevel || !lower_top || output_count<2)return 0;
    if(routed_reverse==requested_reverse)return 1;
    if(getenv("AM2R_DISPLAY_DIAGNOSTICS"))fprintf(stderr,"NATIVE_ROUTE request reversed=%d\n",reverse);
    // Weston retains the fullscreen black backing at the previous output.
    // Apply and commit the non-fullscreen configure first so it is discarded.
    xdg_toplevel_unset_fullscreen(toplevel);
    xdg_toplevel_unset_fullscreen(lower_top);
    wl_surface_commit(surface);wl_surface_commit(lower_surface);
    if(wl_display_roundtrip(display)<0)return 0;
    wl_surface_commit(surface);wl_surface_commit(lower_surface);
    if(wl_display_roundtrip(display)<0)return 0;
    xdg_toplevel_set_fullscreen(toplevel,outputs[requested_reverse?1:0]);
    xdg_toplevel_set_fullscreen(lower_top,outputs[requested_reverse?0:1]);
    wl_surface_commit(surface);wl_surface_commit(lower_surface);
    if(wl_display_roundtrip(display)<0)return 0;
    wl_surface_commit(surface);wl_surface_commit(lower_surface);wl_display_flush(display);
    routed_reverse=requested_reverse;
    return 1;
}
static double span(void){return hypot(contacts[1].x-contacts[0].x,contacts[1].y-contacts[0].y);}
static void touch_down(void *data,struct wl_touch *t,uint32_t serial,uint32_t time,
        struct wl_surface *s,int32_t id,wl_fixed_t x,wl_fixed_t y) {
    (void)data;(void)t;(void)serial;(void)time;
    if(getenv("AM2R_TOUCH_DIAGNOSTICS"))
        fprintf(stderr,"NATIVE_TOUCH down target=%s x=%.1f y=%.1f id=%d\n",
            s==lower_surface?"lower":s==surface?"gameplay":"other",
            wl_fixed_to_double(x),wl_fixed_to_double(y),id);
    int from_gameplay=s==surface;
    // Some handheld firmware maps the only touchscreen to the first output,
    // regardless of its physical panel. Opt in per launcher, not system-wide.
    if(s!=lower_surface && !(from_gameplay && getenv("AM2R_TOUCH_ON_GAMEPLAY")))return;
    for(int i=0;i<2;i++)if(!contacts[i].active){
        contacts[i].id=id;contacts[i].active=1;contacts[i].from_gameplay=from_gameplay;
        contacts[i].x=wl_fixed_to_double(x)*(from_gameplay?(double)lower_width/width:1);
        contacts[i].y=wl_fixed_to_double(y)*(from_gameplay?(double)lower_height/height:1);
        if(i==0){origin_x=touch_x=contacts[i].x;origin_y=touch_y=contacts[i].y;moved=0;}
        else{last_span=span();moved=1;}
        touch_events++;return;
    }
}
static void touch_motion(void *data,struct wl_touch *t,uint32_t time,int32_t id,wl_fixed_t x,wl_fixed_t y){
    (void)data;(void)t;(void)time;
    for(int i=0;i<2;i++)if(contacts[i].active && contacts[i].id==id){
        double nx=wl_fixed_to_double(x),ny=wl_fixed_to_double(y);
        if(contacts[i].from_gameplay){nx*=(double)lower_width/width;ny*=(double)lower_height/height;}
        double dx=nx-contacts[i].x,dy=ny-contacts[i].y;
        contacts[i].x=nx;contacts[i].y=ny;
        if(contacts[0].active && contacts[1].active){
            double current=span();if(current>1 && last_span>1)zoom_delta+=log(current/last_span)/log(2.0);
            last_span=current;moved=1;
        } else if(i==0){
            touch_x=nx;touch_y=ny;
            if(hypot(nx-origin_x,ny-origin_y)>8)moved=1;
            if(moved){drag_x+=dx;drag_y+=dy;}
        }
        touch_events++;return;
    }
}
static void touch_up(void *data,struct wl_touch *t,uint32_t serial,uint32_t time,int32_t id){
    (void)data;(void)t;(void)serial;(void)time;
    for(int i=0;i<2;i++)if(contacts[i].active && contacts[i].id==id){
        if(i==0 && !moved && !contacts[1].active)tapped=1;
        contacts[i].active=0;
        if(i==0 && contacts[1].active){
            contacts[0]=contacts[1];contacts[1].active=0;
            touch_x=contacts[0].x;touch_y=contacts[0].y;moved=1;
        }
        touch_events++;return;
    }
}
static void touch_frame(void *data,struct wl_touch *t){(void)data;(void)t;}
static void touch_cancel(void *data,struct wl_touch *t){
    (void)data;(void)t;contacts[0].active=contacts[1].active=0;
    moved=1;tapped=0;drag_x=drag_y=zoom_delta=0;
}
static const struct wl_touch_listener touch_listener={.down=touch_down,.up=touch_up,
    .motion=touch_motion,.frame=touch_frame,.cancel=touch_cancel};
static void seat_caps(void *data,struct wl_seat *seat,uint32_t caps){
    (void)data;
    if(getenv("AM2R_TOUCH_DIAGNOSTICS"))fprintf(stderr,"NATIVE_TOUCH seat capabilities=%u\n",caps);
    if((caps & WL_SEAT_CAPABILITY_TOUCH) && !input_touch){
        input_touch=wl_seat_get_touch(seat);wl_touch_add_listener(input_touch,&touch_listener,NULL);
    }else if(!(caps & WL_SEAT_CAPABILITY_TOUCH) && input_touch){
        wl_touch_destroy(input_touch);input_touch=NULL;touch_cancel(NULL,NULL);
    }
}
static void seat_name(void *data,struct wl_seat *seat,const char *name){(void)data;(void)seat;(void)name;}
static const struct wl_seat_listener seat_listener={.capabilities=seat_caps,.name=seat_name};
static void native_bind_seat(struct wl_registry *registry,uint32_t name,uint32_t version){
    if(input_seat)return;
    input_seat=wl_registry_bind(registry,name,&wl_seat_interface,version<5?version:5);
    wl_seat_add_listener(input_seat,&seat_listener,NULL);
}
PUBLIC const char *am2r_native_lower_input(double w,double h){
    static char result[512];
    if(!tapped && drag_x==0 && drag_y==0 && zoom_delta==0)return "";
    double scale=fmax(1,floor(fmin(lower_width/w,lower_height/h)));
    double left=(lower_width-w*scale)/2,top=(lower_height-h*scale)/2;
    snprintf(result,sizeof(result),"{\"dx\":%.5f,\"dy\":%.5f,\"zoom\":%.5f,\"tap\":%s,\"x\":%.5f,\"y\":%.5f,\"originX\":%.5f,\"originY\":%.5f}",
        drag_x/scale,drag_y/scale,zoom_delta,tapped?"true":"false",(touch_x-left)/scale,
        (touch_y-top)/scale,(origin_x-left)/scale,(origin_y-top)/scale);
    drag_x=drag_y=zoom_delta=0;tapped=0;return result;
}
PUBLIC unsigned long am2r_native_touch_events(void){return touch_events;}
