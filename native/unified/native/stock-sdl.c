/* Single-screen adapter using the firmware's SDL2 KMSDRM backend. */
#include "stock-sdl.h"
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void *sdl_library, *egl_library, *window, *bootstrap_context;
static EGLDisplay display;
static EGLSurface surface;
static EGLConfig config;
static int attempted, video_started;
static EGLSurface (*get_surface)(EGLint);
static EGLContext (*get_context)(void);

#define SDL_FUNCTION(result, name, arguments) static result (*sdl_##name) arguments
SDL_FUNCTION(int, VideoInit, (const char *));
SDL_FUNCTION(void, VideoQuit, (void));
SDL_FUNCTION(const char *, GetError, (void));
SDL_FUNCTION(const char *, GetCurrentVideoDriver, (void));
SDL_FUNCTION(int, GL_SetAttribute, (int, int));
SDL_FUNCTION(void *, CreateWindow, (const char *, int, int, int, int, unsigned int));
SDL_FUNCTION(void, DestroyWindow, (void *));
SDL_FUNCTION(void *, GL_CreateContext, (void *));
SDL_FUNCTION(int, GL_MakeCurrent, (void *, void *));
SDL_FUNCTION(void *, GL_GetProcAddress, (const char *));
SDL_FUNCTION(void, GL_DeleteContext, (void *));
SDL_FUNCTION(void, GL_SwapWindow, (void *));
SDL_FUNCTION(int, GL_SetSwapInterval, (int));
SDL_FUNCTION(int, PollEvent, (void *));
SDL_FUNCTION(int, ShowCursor, (int));
#undef SDL_FUNCTION

static void close_stock_display(void)
{
    if (bootstrap_context) sdl_GL_DeleteContext(bootstrap_context);
    if (window) sdl_DestroyWindow(window);
    if (video_started) sdl_VideoQuit();
    bootstrap_context = window = NULL;
    surface = EGL_NO_SURFACE;
    display = EGL_NO_DISPLAY;
    video_started = 0;
}

int am2arm_stock_enabled(void)
{
    const char *value = getenv("AM2ARM_STOCK_DISPLAY");
    return value && !strcmp(value, "1");
}

EGLDisplay am2arm_stock_display(void)
{
    if (attempted) return display;
    attempted = 1;
    const char *sdl_path = getenv("AM2ARM_FIRMWARE_SDL");
    const char *egl_path = getenv("LIBGL_EGL");
    sdl_library = dlopen(sdl_path && *sdl_path ? sdl_path : "libSDL2-2.0.so.0", RTLD_NOW | RTLD_LOCAL);
    egl_library = dlopen(egl_path && *egl_path ? egl_path : "/usr/lib/libEGL.so.1", RTLD_NOW | RTLD_LOCAL);
    if (!sdl_library || !egl_library) {
        fprintf(stderr, "Stock display: library unavailable: %s\n", dlerror());
        return EGL_NO_DISPLAY;
    }
#define LOAD_SDL(name) do { \
    sdl_##name = dlsym(sdl_library, "SDL_" #name); \
    if (!sdl_##name) { fprintf(stderr, "Stock display: missing SDL_%s\n", #name); return EGL_NO_DISPLAY; } \
} while (0)
    LOAD_SDL(VideoInit); LOAD_SDL(VideoQuit); LOAD_SDL(GetError);
    LOAD_SDL(GetCurrentVideoDriver); LOAD_SDL(GL_SetAttribute);
    LOAD_SDL(CreateWindow); LOAD_SDL(DestroyWindow); LOAD_SDL(GL_CreateContext);
    LOAD_SDL(GL_MakeCurrent); LOAD_SDL(GL_GetProcAddress);
    LOAD_SDL(GL_DeleteContext); LOAD_SDL(GL_SwapWindow); LOAD_SDL(GL_SetSwapInterval);
    LOAD_SDL(PollEvent); LOAD_SDL(ShowCursor);
#undef LOAD_SDL
    EGLDisplay (*get_display)(void) = dlsym(egl_library, "eglGetCurrentDisplay");
    get_surface = dlsym(egl_library, "eglGetCurrentSurface");
    get_context = dlsym(egl_library, "eglGetCurrentContext");
    EGLBoolean (*query_context)(EGLDisplay, EGLContext, EGLint, EGLint *) = dlsym(egl_library, "eglQueryContext");
    EGLBoolean (*choose_config)(EGLDisplay, const EGLint *, EGLConfig *, EGLint, EGLint *) = dlsym(egl_library, "eglChooseConfig");
    if (!get_display || !get_surface || !get_context || !query_context || !choose_config)
        return EGL_NO_DISPLAY;

    /* Select this library's backend explicitly. The game's separate X11 input
       runtime retains its own SDL_VIDEODRIVER setting. */
    if (sdl_VideoInit("KMSDRM") < 0) goto failed;
    video_started = 1;
    atexit(close_stock_display);
    if (sdl_GL_SetAttribute(21, 4) < 0 || sdl_GL_SetAttribute(17, 2) < 0 ||
        sdl_GL_SetAttribute(18, 0) < 0 || sdl_GL_SetAttribute(5, 1) < 0 ||
        sdl_GL_SetAttribute(0, 8) < 0 || sdl_GL_SetAttribute(1, 8) < 0 ||
        sdl_GL_SetAttribute(2, 8) < 0 || sdl_GL_SetAttribute(3, 0) < 0 ||
        sdl_GL_SetAttribute(6, 16) < 0 || sdl_GL_SetAttribute(7, 8) < 0) goto failed;
    int width = 640, height = 480;
    const char *size = getenv("AM2ARM_KMS_SIZE");
    char trailing;
    if (size && (sscanf(size, "%4dx%4d%c", &width, &height, &trailing) != 2 || width < 1 || height < 1)) {
        fprintf(stderr, "Invalid KMS panel size.\n");
        close_stock_display();
        return EGL_NO_DISPLAY;
    }
    window = sdl_CreateWindow("AM2ARM", 0x1FFF0000, 0x1FFF0000, width, height, 0x1007);
    if (!window) goto failed;
    bootstrap_context = sdl_GL_CreateContext(window);
    if (!bootstrap_context) goto failed;
    /* KMSDRM defers fullscreen surface recreation until its first swap.
       Finish that operation before GL4ES caches the surface or owns resources. */
    void (*clear_color)(float, float, float, float) = sdl_GL_GetProcAddress("glClearColor");
    void (*clear)(unsigned int) = sdl_GL_GetProcAddress("glClear");
    if (!clear_color || !clear) goto failed;
    for (int frame = 0; frame < 2; ++frame) {
        clear_color(0, 0, 0, 1);
        clear(0x00004000);
        sdl_GL_SwapWindow(window);
    }
    display = get_display();
    surface = get_surface(EGL_DRAW);
    EGLint id = 0, count = 0;
    if (!display || !surface || !query_context(display, get_context(), EGL_CONFIG_ID, &id)) goto failed;
    const EGLint attributes[] = {EGL_CONFIG_ID, id, EGL_NONE};
    if (!choose_config(display, attributes, &config, 1, &count) || count != 1) goto failed;
    sdl_GL_SetSwapInterval(1);
    sdl_ShowCursor(0);
    fprintf(stderr, "Stock display: SDL %s, EGL config %d, %dx%d single screen\n",
            sdl_GetCurrentVideoDriver(), id, width, height);
    return display;
failed:
    fprintf(stderr, "Stock display startup failed: %s\n", sdl_GetError());
    close_stock_display();
    return EGL_NO_DISPLAY;
}

EGLSurface am2arm_stock_surface(void) { return surface; }
EGLConfig am2arm_stock_config(void) { return config; }
EGLBoolean am2arm_stock_make_current(EGLContext context)
{
    /* SDL must track the game's context when its KMS backend rebinds a surface. */
    if (sdl_GL_MakeCurrent(context ? window : NULL, context) < 0) {
        fprintf(stderr, "Stock display context failed: %s\n", sdl_GetError());
        return EGL_FALSE;
    }
    return EGL_TRUE;
}
int am2arm_stock_surface_owned(EGLSurface value)
{
    return am2arm_stock_enabled() && value && value == surface;
}

void am2arm_stock_swap(void)
{
    static unsigned int checked_frames;
    if (!window) return;
    EGLContext previous_context = checked_frames < 3 ? get_context() : EGL_NO_CONTEXT;
    union { void *alignment; unsigned char bytes[56]; } event;
    while (sdl_PollEvent(&event)) { }
    sdl_GL_SwapWindow(window);
    if (checked_frames < 3) {
        int context_ok = previous_context && get_context() == previous_context;
        int surface_ok = get_surface(EGL_DRAW) == surface;
        fprintf(stderr, "Stock display frame %u: context=%s surface=%s\n",
                ++checked_frames, context_ok ? "stable" : "changed",
                surface_ok ? "stable" : "changed");
    }
}

void am2arm_stock_interval(int interval)
{
    if (window) sdl_GL_SetSwapInterval(interval ? 1 : 0);
}
