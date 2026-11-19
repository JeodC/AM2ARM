/* Private native Wayland adapter for the game's two physical displays. */
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>
#include <wayland-egl.h>
#include "xdg-shell-client-protocol.h"

static struct wl_display *display;
static struct wl_compositor *compositor;
static struct xdg_wm_base *shell;
static struct wl_surface *surface;
static struct xdg_surface *xdg_surface;
static struct xdg_toplevel *toplevel;
static struct wl_egl_window *window;
static int configured, closed, width, height;
static struct wl_output *outputs[8];
static unsigned output_count;

static void output_enter(void *data, struct wl_surface *s, struct wl_output *out) {
    (void)data;
    if (!getenv("AM2R_DISPLAY_DIAGNOSTICS")) return;
    for (unsigned i=0;i<output_count;i++) if(outputs[i]==out)
        fprintf(stderr,"NATIVE_ROUTE %s enter output %u\n",s==surface?"gameplay":"lower",i);
}
static void output_leave(void *data, struct wl_surface *s, struct wl_output *out) {
    (void)data;
    if (!getenv("AM2R_DISPLAY_DIAGNOSTICS")) return;
    for (unsigned i=0;i<output_count;i++) if(outputs[i]==out)
        fprintf(stderr,"NATIVE_ROUTE %s leave output %u\n",s==surface?"gameplay":"lower",i);
}
static const struct wl_surface_listener output_listener={.enter=output_enter,.leave=output_leave};

static void ping(void *data, struct xdg_wm_base *base, uint32_t serial) {
    (void)data;
    xdg_wm_base_pong(base, serial);
}
static const struct xdg_wm_base_listener shell_listener = { .ping = ping };

static void native_bind_seat(struct wl_registry *,uint32_t,uint32_t);

static void global(void *data, struct wl_registry *registry, uint32_t name,
                   const char *interface, uint32_t version) {
    (void)data;
    if (!strcmp(interface, "wl_seat")) native_bind_seat(registry,name,version);
    if (!strcmp(interface, "wl_compositor"))
        compositor = wl_registry_bind(registry, name, &wl_compositor_interface,
                                      version < 4 ? version : 4);
    if (!strcmp(interface, "xdg_wm_base")) {
        shell = wl_registry_bind(registry, name, &xdg_wm_base_interface, 1);
        xdg_wm_base_add_listener(shell, &shell_listener, NULL);
    }
    if (!strcmp(interface, "wl_output") && output_count < 8)
        outputs[output_count++] = wl_registry_bind(registry, name,
                                                   &wl_output_interface, 1);
}
static void removed(void *data, struct wl_registry *registry, uint32_t name) {
    (void)data; (void)registry; (void)name;
}
static const struct wl_registry_listener registry_listener = { global, removed };

void *native_probe_wayland_display(void) {
    if (display) return display;
    display = wl_display_connect(NULL);
    if (!display) return NULL;
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    if (wl_display_roundtrip(display) < 0 || !compositor || !shell) {
        fprintf(stderr, "NATIVE_WAYLAND missing compositor or xdg shell\n");
        return NULL;
    }
    return display;
}

static void configure_surface(void *data, struct xdg_surface *s, uint32_t serial) {
    (void)data;
    xdg_surface_ack_configure(s, serial);
    configured = 1;
}
static const struct xdg_surface_listener surface_listener = { configure_surface };
static void configure_toplevel(void *data, struct xdg_toplevel *t, int32_t w,
                               int32_t h, struct wl_array *states) {
    (void)data; (void)t; (void)states;
    if (w > 0 && h > 0) {
        width = w; height = h;
        if (window) wl_egl_window_resize(window, width, height, 0, 0);
    }
}
static void close_toplevel(void *data, struct xdg_toplevel *t) {
    (void)data; (void)t; closed = 1;
}
static const struct xdg_toplevel_listener toplevel_listener = {
    .configure = configure_toplevel, .close = close_toplevel
};

void *native_probe_wayland_window(int requested_width, int requested_height) {
    if (window) return window;
    if (!native_probe_wayland_display()) return NULL;
    width = requested_width; height = requested_height;
    surface = wl_compositor_create_surface(compositor);
    wl_surface_add_listener(surface,&output_listener,NULL);
    xdg_surface = xdg_wm_base_get_xdg_surface(shell, surface);
    xdg_surface_add_listener(xdg_surface, &surface_listener, NULL);
    toplevel = xdg_surface_get_toplevel(xdg_surface);
    xdg_toplevel_add_listener(toplevel, &toplevel_listener, NULL);
    xdg_toplevel_set_title(toplevel, "AM2R");
    xdg_toplevel_set_app_id(toplevel, "org.am2r.gameplay");
    struct wl_output *output = NULL;
    const char *choice = getenv("LIBGL_NATIVE_OUTPUT");
    if (choice && *choice) {
        char *end;
        long selected = strtol(choice, &end, 10);
        if (*end || selected < 0 || selected >= output_count) {
            fprintf(stderr, "NATIVE_WAYLAND invalid output selection\n");
            return NULL;
        }
        output = outputs[selected];
        fprintf(stderr, "NATIVE_WAYLAND selected output %ld of %u\n",
                selected, output_count);
    }
    xdg_toplevel_set_fullscreen(toplevel, output);
    wl_surface_commit(surface);
    for (int attempts = 0; !configured && attempts < 10; ++attempts)
        if (wl_display_roundtrip(display) < 0) return NULL;
    if (!configured) return NULL;
    window = wl_egl_window_create(surface, width, height);
    fprintf(stderr, "NATIVE_WAYLAND window %dx%d\n", width, height);
    return window;
}

int native_probe_wayland_pump(void) {
    if (!display || closed) return 0;
    while (wl_display_prepare_read(display) != 0)
        if (wl_display_dispatch_pending(display) < 0) return 0;
    wl_display_flush(display);
    struct pollfd fd = { wl_display_get_fd(display), POLLIN, 0 };
    if (poll(&fd, 1, 0) > 0 && (fd.revents & POLLIN)) {
        if (wl_display_read_events(display) < 0) return 0;
    } else wl_display_cancel_read(display);
    return wl_display_dispatch_pending(display) >= 0 && !closed;
}

#include "native-lower.inc"
