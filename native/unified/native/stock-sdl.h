#ifndef AM2ARM_STOCK_SDL_H
#define AM2ARM_STOCK_SDL_H
#include <EGL/egl.h>
int am2arm_stock_enabled(void);
EGLDisplay am2arm_stock_display(void);
EGLSurface am2arm_stock_surface(void);
EGLConfig am2arm_stock_config(void);
EGLBoolean am2arm_stock_make_current(EGLContext context);
int am2arm_stock_surface_owned(EGLSurface surface);
void am2arm_stock_swap(void);
void am2arm_stock_interval(int interval);
#endif
